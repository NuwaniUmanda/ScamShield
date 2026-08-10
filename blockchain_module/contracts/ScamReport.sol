// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ScamReport {
    struct Report {
        string reportId;
        string reportHash; // SHA-256 hash of report content
        uint256 timestamp;
        address submitter;
    }

    mapping(string => Report) private reports;
    string[] private reportIds;

    event ReportStored(string reportId, string reportHash, uint256 timestamp, address submitter);

    function storeReport(string memory _reportId, string memory _reportHash) public {
        require(bytes(reports[_reportId].reportId).length == 0, "Report already exists");

        reports[_reportId] = Report({
            reportId: _reportId,
            reportHash: _reportHash,
            timestamp: block.timestamp,
            submitter: msg.sender
        });

        reportIds.push(_reportId);

        emit ReportStored(_reportId, _reportHash, block.timestamp, msg.sender);
    }

    function getReport(string memory _reportId) public view returns (
        string memory reportHash,
        uint256 timestamp,
        address submitter
    ) {
        Report memory r = reports[_reportId];
        require(bytes(r.reportId).length != 0, "Report not found");
        return (r.reportHash, r.timestamp, r.submitter);
    }

    function getTotalReports() public view returns (uint256) {
        return reportIds.length;
    }
}