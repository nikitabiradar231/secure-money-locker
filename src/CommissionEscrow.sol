// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CommissionEscrow is ReentrancyGuard {
    enum Status {
        Funded,
        Delivered,
        Disputed,
        Paid,
        Refunded
    }

    struct Commission {
        address collector;
        address artisan;
        address arbiter;
        uint256 amount;
        uint256 deadline;
        Status status;
    }

    uint256 private _nextCommissionId;

    mapping(uint256 => Commission) public commissions;

    function createCommission(address artisan, address arbiter, uint256 deadline)
        external
        payable
        returns (uint256 commissionId)
    {
        require(artisan != address(0), "invalid artisan");
        require(arbiter != address(0), "invalid arbiter");
        require(artisan != msg.sender, "collector cannot be artisan");
        require(arbiter != msg.sender, "collector cannot be arbiter");
        require(arbiter != artisan, "arbiter cannot be artisan");
        require(msg.value > 0, "commission must be funded");
        require(deadline > block.timestamp, "deadline must be in future");

        commissionId = _nextCommissionId++;

        commissions[commissionId] = Commission({
            collector: msg.sender,
            artisan: artisan,
            arbiter: arbiter,
            amount: msg.value,
            deadline: deadline,
            status: Status.Funded
        });
    }

    function confirmDelivery(uint256 commissionId) external {
        Commission storage commission = commissions[commissionId];

        require(commission.collector != address(0), "commission does not exist");
        require(msg.sender == commission.collector, "only collector can confirm");
        require(commission.status == Status.Funded, "invalid commission status");

        commission.status = Status.Delivered;
    }

    function releasePayment(uint256 commissionId) external nonReentrant {
        Commission storage commission = commissions[commissionId];

        require(commission.collector != address(0), "commission does not exist");
        require(commission.status == Status.Delivered, "delivery not confirmed");
        require(msg.sender == commission.collector, "only collector can release");

        uint256 amount = commission.amount;

        commission.amount = 0;
        commission.status = Status.Paid;

        (bool success,) = payable(commission.artisan).call{value: amount}("");
        require(success, "payment failed");
    }

    function refundAfterDeadline(uint256 commissionId) external nonReentrant {
        Commission storage commission = commissions[commissionId];

        require(commission.collector != address(0), "commission does not exist");
        require(msg.sender == commission.collector, "only collector can refund");
        require(block.timestamp >= commission.deadline, "deadline not reached");
        require(commission.status == Status.Funded, "refund unavailable");

        uint256 amount = commission.amount;

        commission.amount = 0;
        commission.status = Status.Refunded;

        (bool success,) = payable(commission.collector).call{value: amount}("");
        require(success, "refund failed");
    }

    function raiseDispute(uint256 commissionId) external {
        Commission storage commission = commissions[commissionId];

        require(commission.collector != address(0), "commission does not exist");
        require(msg.sender == commission.collector || msg.sender == commission.artisan, "only parties can dispute");
        require(commission.status == Status.Funded, "invalid commission status");

        commission.status = Status.Disputed;
    }

    function resolveDispute(uint256 commissionId, bool payArtisan) external nonReentrant {
        Commission storage commission = commissions[commissionId];

        require(commission.collector != address(0), "commission does not exist");
        require(msg.sender == commission.arbiter, "only arbiter can resolve");
        require(commission.status == Status.Disputed, "not disputed");

        uint256 amount = commission.amount;

        commission.amount = 0;

        if (payArtisan) {
            commission.status = Status.Paid;

            (bool success,) = payable(commission.artisan).call{value: amount}("");
            require(success, "payment failed");
        } else {
            commission.status = Status.Refunded;

            (bool success,) = payable(commission.collector).call{value: amount}("");
            require(success, "refund failed");
        }
    }
}
