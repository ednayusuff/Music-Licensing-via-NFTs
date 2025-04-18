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

## License

This project is licensed under the MIT License.