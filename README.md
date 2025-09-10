# Music Licensing NFT Platform

A decentralized platform for buying, selling, and managing music licensing rights through non-fungible tokens (NFTs) on the Stacks blockchain.

## Overview

This smart contract enables musicians and artists to tokenize their music licensing rights as NFTs. Verified artists can mint license tokens, set royalty percentages, and define usage rights. Buyers can purchase these licenses and gain specific rights to use the music according to the terms encoded in the token.

## Features

- **Artist Verification**: Only verified artists can mint music license NFTs
- **License Minting**: Create NFTs representing music licensing rights
- **Royalty Management**: Automatic royalty payments to original artists on secondary sales
- **Usage Rights**: Define commercial use, derivative works, territory, and duration
- **Marketplace**: List, unlist, buy, and transfer music licenses

## Contract Functions

### Read-Only Functions

- `get-last-token-id`: Returns the ID of the last minted token
- `get-token-metadata`: Returns metadata for a specific token
- `get-token-listing`: Returns listing information if a token is for sale
- `get-license-rights`: Returns the usage rights associated with a license
- `is-artist-verified`: Checks if an artist is verified
- `get-royalty-info`: Returns royalty information for a token
- `get-owner`: Returns the current owner of a token

### Public Functions

- `verify-artist`: Verifies an artist (contract owner only)
- `mint-music-license`: Creates a new music license NFT
- `list-license-for-sale`: Lists a license for sale at a specified price
- `unlist-license`: Removes a license from sale
- `buy-license`: Purchases a listed license
- `transfer-license`: Transfers a license to another user
- `update-license-rights`: Updates the usage rights for a license

## Usage Examples

### Verifying an Artist

```clarity
(contract-call? .music verify-artist 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Minting a Music License

```clarity
(contract-call? .music mint-music-license "Song Title" "Description of the song and license" "Commercial" u10 true false "Worldwide" u31536000)
```

### Listing a License for Sale

```clarity
(contract-call? .music list-license-for-sale u1 u1000000)
```

### Buying a License

```clarity
(contract-call? .music buy-license u1)
```

## License Analytics Extension

The `music-analytics` contract provides comprehensive performance tracking and insights for music licenses:

### Features

- **Performance Metrics**: Track views, revenue, and popularity scores for each license
- **Geographic Analytics**: Monitor usage patterns across different regions 
- **Artist Insights**: Aggregate performance data for artists across all their licenses
- **Daily Revenue Tracking**: Detailed day-by-day revenue breakdown
- **License Rankings**: Dynamic popularity-based ranking system

### Analytics Functions

#### Recording Events

```clarity
;; Record a license view/usage event
(contract-call? .music-analytics record-license-view u1 "US")

;; Record revenue from license usage
(contract-call? .music-analytics record-license-revenue u1 u1000000 "EU")

;; Update artist stats
(contract-call? .music-analytics update-artist-stats 'ST1ARTIST123 u5)
```

#### Querying Analytics

```clarity
;; Get comprehensive license statistics
(contract-call? .music-analytics get-license-stats u1)

;; Check license performance summary
(contract-call? .music-analytics get-license-performance u1)

;; View geographic usage for a region
(contract-call? .music-analytics get-geographic-usage u1 "ASIA")

;; Get daily revenue data
(contract-call? .music-analytics get-daily-revenue u1 u100)

;; View artist analytics
(contract-call? .music-analytics get-artist-analytics 'ST1ARTIST123)
```

### Use Cases

1. **Artists** can track performance metrics across all their licenses
2. **License holders** can monitor usage patterns and revenue trends
3. **Platforms** can identify trending content and popular territories
4. **Analytics dashboards** can provide insights for strategic decisions

## License

This project is licensed under the MIT License.
