// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScamShieldRegistry
 * @dev Immutable Decentralized Scam Registry for storing verified scam hashes.
 */
contract ScamShieldRegistry {
    address public owner;

    struct ScamRecord {
        string reportId;
        string scamType;
        uint8 riskScore;
        string dataHash;
        uint256 timestamp;
        bool isVerified;
    }

    mapping(bytes32 => ScamRecord) public records;
    bytes32[] public recordHashes;

    event ScamRegistered(
        bytes32 indexed txHash,
        string reportId,
        string scamType,
        uint8 riskScore,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only ScamShield Admin can record");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerScam(
        string memory _reportId,
        string memory _scamType,
        uint8 _riskScore,
        string memory _dataHash
    ) external onlyOwner returns (bytes32) {
        bytes32 hashKey = keccak256(
            abi.encodePacked(_reportId, _scamType, _riskScore, _dataHash, block.timestamp)
        );

        records[hashKey] = ScamRecord({
            reportId: _reportId,
            scamType: _scamType,
            riskScore: _riskScore,
            dataHash: _dataHash,
            timestamp: block.timestamp,
            isVerified: true
        });

        recordHashes.push(hashKey);

        emit ScamRegistered(hashKey, _reportId, _scamType, _riskScore, block.timestamp);
        return hashKey;
    }

    function verifyScam(bytes32 _hashKey) external view returns (
        string memory reportId,
        string memory scamType,
        uint8 riskScore,
        uint256 timestamp,
        bool isVerified
    ) {
        ScamRecord memory rec = records[_hashKey];
        require(rec.isVerified, "Record does not exist");
        return (rec.reportId, rec.scamType, rec.riskScore, rec.timestamp, rec.isVerified);
    }
}
