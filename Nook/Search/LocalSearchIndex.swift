import Foundation

/// Fast in-memory tokenized search engine for local-first Nook items.
///
/// Features:
/// - Sub-millisecond queries with zero external dependencies or background servers.
/// - Case-insensitive prefix and multi-token matching across title, content, and item/object types.
/// - Weighted scoring to rank title and object type matches above body content.
/// - Search across both active and archived items so everything stays discoverable.
final class LocalSearchIndex: @unchecked Sendable {
    
    struct SearchResult: Identifiable, Equatable {
        let item: NookItem
        let score: Double
        let matchesTitle: Bool
        let matchesContent: Bool
        let matchesType: Bool
        let isArchived: Bool
        
        var id: UUID { item.id }
    }
    
    private let lock = NSLock()
    private var indexedItems: [UUID: NookItem] = [:]
    
    // Inverted index mapping token -> Set of item IDs
    private var invertedIndex: [String: Set<UUID>] = [:]
    
    // Pre-tokenized items for rapid score calculation
    private struct ItemTokens {
        let titleTokens: Set<String>
        let contentTokens: Set<String>
        let typeTokens: Set<String>
    }
    private var itemTokenCache: [UUID: ItemTokens] = [:]
    
    // MARK: - Index Management
    
    /// Replaces or builds the entire search index from an array of NookItems.
    func rebuild(with items: [NookItem]) {
        lock.lock()
        defer { lock.unlock() }
        
        indexedItems.removeAll(keepingCapacity: true)
        invertedIndex.removeAll(keepingCapacity: true)
        itemTokenCache.removeAll(keepingCapacity: true)
        
        for item in items {
            indexItemInternal(item)
        }
    }
    
    /// Indexes or updates a single item in the search index.
    func index(item: NookItem) {
        lock.lock()
        defer { lock.unlock() }
        indexItemInternal(item)
    }
    
    /// Removes an item from the search index.
    func remove(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        
        indexedItems.removeValue(forKey: id)
        itemTokenCache.removeValue(forKey: id)
        
        // Remove ID from inverted index entries
        for (token, var ids) in invertedIndex {
            if ids.remove(id) != nil {
                if ids.isEmpty {
                    invertedIndex.removeValue(forKey: token)
                } else {
                    invertedIndex[token] = ids
                }
            }
        }
    }
    
    private func indexItemInternal(_ item: NookItem) {
        let titleTokens = Set(tokenize(item.title))
        let contentTokens = Set(tokenize(item.content))
        let typeTokens = Set(tokenize("\(item.itemType.displayName) \(item.objectType.displayName)"))
        
        indexedItems[item.id] = item
        itemTokenCache[item.id] = ItemTokens(
            titleTokens: titleTokens,
            contentTokens: contentTokens,
            typeTokens: typeTokens
        )
        
        let allTokens = titleTokens.union(contentTokens).union(typeTokens)
        for token in allTokens {
            invertedIndex[token, default: []].insert(item.id)
        }
    }
    
    // MARK: - Search Query Execution
    
    /// Searches indexed items for the given query string.
    func search(query: String, includeArchived: Bool = true, limit: Int = 25) -> [SearchResult] {
        let rawQueryTokens = tokenize(query)
        guard !rawQueryTokens.isEmpty else {
            lock.lock()
            defer { lock.unlock() }
            let all = indexedItems.values
                .filter { includeArchived || !$0.isArchived }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(limit)
            return all.map {
                SearchResult(
                    item: $0,
                    score: 1.0,
                    matchesTitle: false,
                    matchesContent: false,
                    matchesType: false,
                    isArchived: $0.isArchived
                )
            }
        }
        
        lock.lock()
        defer { lock.unlock() }
        
        var candidateScores: [UUID: (score: Double, mTitle: Bool, mContent: Bool, mType: Bool)] = [:]
        
        for qToken in rawQueryTokens {
            // Find all matching index tokens (exact match or prefix match)
            var matchingItemIDs = Set<UUID>()
            
            for (idxToken, itemIDs) in invertedIndex {
                if idxToken == qToken || idxToken.hasPrefix(qToken) {
                    matchingItemIDs.formUnion(itemIDs)
                }
            }
            
            for itemID in matchingItemIDs {
                guard let tokens = itemTokenCache[itemID] else { continue }
                
                var tokenScore: Double = 0.0
                var matchTitle = false
                var matchContent = false
                var matchType = false
                
                // 1. Title match weighting (High priority)
                for t in tokens.titleTokens {
                    if t == qToken {
                        tokenScore += 10.0
                        matchTitle = true
                    } else if t.hasPrefix(qToken) {
                        tokenScore += 5.0
                        matchTitle = true
                    }
                }
                
                // 2. Object & Item type match weighting (Medium-high priority)
                for t in tokens.typeTokens {
                    if t == qToken {
                        tokenScore += 7.0
                        matchType = true
                    } else if t.hasPrefix(qToken) {
                        tokenScore += 4.0
                        matchType = true
                    }
                }
                
                // 3. Body content match weighting
                for c in tokens.contentTokens {
                    if c == qToken {
                        tokenScore += 3.0
                        matchContent = true
                    } else if c.hasPrefix(qToken) {
                        tokenScore += 1.5
                        matchContent = true
                    }
                }
                
                let current = candidateScores[itemID] ?? (score: 0.0, mTitle: false, mContent: false, mType: false)
                candidateScores[itemID] = (
                    score: current.score + tokenScore,
                    mTitle: current.mTitle || matchTitle,
                    mContent: current.mContent || matchContent,
                    mType: current.mType || matchType
                )
            }
        }
        
        var results: [SearchResult] = []
        for (itemID, meta) in candidateScores {
            guard let item = indexedItems[itemID] else { continue }
            if !includeArchived && item.isArchived {
                continue
            }
            results.append(SearchResult(
                item: item,
                score: meta.score,
                matchesTitle: meta.mTitle,
                matchesContent: meta.mContent,
                matchesType: meta.mType,
                isArchived: item.isArchived
            ))
        }
        
        // Sort results: highest relevance score first, tie-break by recency
        results.sort {
            if abs($0.score - $1.score) > 0.001 {
                return $0.score > $1.score
            }
            return $0.item.updatedAt > $1.item.updatedAt
        }
        
        return Array(results.prefix(limit))
    }
    
    // MARK: - Tokenizer
    
    private func tokenize(_ text: String) -> [String] {
        let lowered = text.lowercased()
        let words = lowered.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return words.filter { !$0.isEmpty }
    }
}
