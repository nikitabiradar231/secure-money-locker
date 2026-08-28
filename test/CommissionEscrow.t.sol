// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CommissionEscrow} from "../src/CommissionEscrow.sol";

contract CommissionEscrowTest is Test {
    CommissionEscrow escrow;

    address collector = address(1);
    address artisan = address(2);
    address arbiter = address(3);

    function setUp() public {
        escrow = new CommissionEscrow();

        vm.deal(collector, 10 ether);
    }

    function testCreateCommissionLocksFunds() public {
        uint256 amount = 1 ether;
        uint256 deadline = block.timestamp + 7 days;

        vm.prank(collector);

        uint256 commissionId = escrow.createCommission{value: amount}(
            artisan,
            arbiter,
            deadline
        );

        assertEq(address(escrow).balance, amount);

        (
            address storedCollector,
            address storedArtisan,
            address storedArbiter,
            uint256 storedAmount,
            uint256 storedDeadline,
            CommissionEscrow.Status status
        ) = escrow.commissions(commissionId);

        assertEq(storedCollector, collector);
        assertEq(storedArtisan, artisan);
        assertEq(storedArbiter, arbiter);
        assertEq(storedAmount, amount);
        assertEq(storedDeadline, deadline);
        assertEq(uint8(status), uint8(CommissionEscrow.Status.Funded));
    }
    function testCannotReleaseBeforeDelivery() public {
    uint256 amount = 1 ether;
    uint256 deadline = block.timestamp + 7 days;

    vm.prank(collector);

    uint256 commissionId = escrow.createCommission{value: amount}(
        artisan,
        arbiter,
        deadline
    );

    vm.prank(collector);

    vm.expectRevert("delivery not confirmed");

    escrow.releasePayment(commissionId);
}
function testReleaseAfterDelivery() public {
    uint256 amount = 1 ether;
    uint256 deadline = block.timestamp + 7 days;

    vm.prank(collector);

    uint256 commissionId = escrow.createCommission{value: amount}(
        artisan,
        arbiter,
        deadline
    );

    uint256 artisanBalanceBefore = artisan.balance;

    vm.prank(collector);
    escrow.confirmDelivery(commissionId);

    vm.prank(collector);
    escrow.releasePayment(commissionId);

    assertEq(artisan.balance, artisanBalanceBefore + amount);
    assertEq(address(escrow).balance, 0);

    (, , , uint256 storedAmount, , CommissionEscrow.Status status) =
        escrow.commissions(commissionId);

    assertEq(storedAmount, 0);
    assertEq(uint8(status), uint8(CommissionEscrow.Status.Paid));
}
function testRefundAfterDeadline() public {
    uint256 amount = 1 ether;
    uint256 deadline = block.timestamp + 1 days;

    vm.prank(collector);

    uint256 commissionId = escrow.createCommission{value: amount}(
        artisan,
        arbiter,
        deadline
    );

    uint256 collectorBalanceBefore = collector.balance;

    // Move blockchain time past the deadline
    vm.warp(deadline + 1);

    vm.prank(collector);
    escrow.refundAfterDeadline(commissionId);

    assertEq(collector.balance, collectorBalanceBefore + amount);
    assertEq(address(escrow).balance, 0);

    (, , , uint256 storedAmount, , CommissionEscrow.Status status) =
        escrow.commissions(commissionId);

    assertEq(storedAmount, 0);
    assertEq(uint8(status), uint8(CommissionEscrow.Status.Refunded));
}
function testArbiterCanResolveDisputeForArtisan() public {
    uint256 amount = 1 ether;
    uint256 deadline = block.timestamp + 7 days;

    vm.prank(collector);

    uint256 commissionId = escrow.createCommission{value: amount}(
        artisan,
        arbiter,
        deadline
    );

    vm.prank(collector);
    escrow.raiseDispute(commissionId);

    uint256 artisanBalanceBefore = artisan.balance;

    vm.prank(arbiter);
    escrow.resolveDispute(commissionId, true);

    assertEq(artisan.balance, artisanBalanceBefore + amount);
    assertEq(address(escrow).balance, 0);

    (, , , uint256 storedAmount, , CommissionEscrow.Status status) =
        escrow.commissions(commissionId);

    assertEq(storedAmount, 0);
    assertEq(uint8(status), uint8(CommissionEscrow.Status.Paid));
}
function testOnlyArbiterCanResolveDispute() public {
    uint256 amount = 1 ether;
    uint256 deadline = block.timestamp + 7 days;

    vm.prank(collector);

    uint256 commissionId = escrow.createCommission{value: amount}(
        artisan,
        arbiter,
        deadline
    );

    vm.prank(collector);
    escrow.raiseDispute(commissionId);

    // Collector cannot resolve
    vm.prank(collector);
    vm.expectRevert("only arbiter can resolve");
    escrow.resolveDispute(commissionId, true);

    // Artisan cannot resolve
    vm.prank(artisan);
    vm.expectRevert("only arbiter can resolve");
    escrow.resolveDispute(commissionId, true);
}
function testCannotReleaseTwice() public {
    uint256 amount = 1 ether;
    uint256 deadline = block.timestamp + 7 days;

    vm.prank(collector);

    uint256 commissionId = escrow.createCommission{value: amount}(
        artisan,
        arbiter,
        deadline
    );

    vm.prank(collector);
    escrow.confirmDelivery(commissionId);

    vm.prank(collector);
    escrow.releasePayment(commissionId);

    // Try to release the same commission again
    vm.prank(collector);
    vm.expectRevert("delivery not confirmed");
    escrow.releasePayment(commissionId);
}
}