# Secure Money Locker — Commission Escrow

A secure, decentralized commission escrow smart contract built with **Solidity, Foundry, and OpenZeppelin**.

The contract securely locks funds for a commission and releases them to the artisan after delivery confirmation. If a commission reaches its deadline without delivery, the collector can request a refund. Disputes can be resolved by a designated arbiter.

## Features

* 💰 **Secure Fund Locking** — Commission funds are held inside the smart contract.
* 📦 **Delivery Confirmation** — The collector confirms when the commissioned work has been delivered.
* 💸 **Payment Release** — Funds are released to the artisan after delivery confirmation.
* 🔄 **Deadline Refund** — The collector can receive a refund after the commission deadline if delivery has not been confirmed.
* ⚖️ **Dispute Resolution** — The collector or artisan can raise a dispute, which can be resolved by the designated arbiter.
* 🛡️ **Reentrancy Protection** — Payment and refund functions use OpenZeppelin's `ReentrancyGuard`.
* 🔐 **Role Validation** — The contract prevents invalid collector, artisan, and arbiter combinations.

## Commission Flow

```text
Collector
    │
    │ Create commission + deposit ETH
    ▼
┌─────────────────────┐
│   CommissionEscrow  │
│                     │
│   Status: Funded    │
└─────────────────────┘
    │
    ├── Delivery confirmed ──► Payment released to Artisan
    │
    ├── Deadline reached ────► Funds refunded to Collector
    │
    └── Dispute raised ──────► Arbiter resolves
                                  │
                         ┌────────┴────────┐
                         ▼                 ▼
                     Pay Artisan      Refund Collector
```

## Smart Contract

The main contract is:

```text
src/CommissionEscrow.sol
```

### Commission Roles

| Role          | Responsibility                                                                                           |
| ------------- | -------------------------------------------------------------------------------------------------------- |
| **Collector** | Creates and funds the commission, confirms delivery, releases payment, and can request a deadline refund |
| **Artisan**   | Receives payment after successful delivery or dispute resolution                                         |
| **Arbiter**   | Resolves disputes between the collector and artisan                                                      |

## Commission Statuses

The contract uses the following states:

* `Funded` — Commission has been created and funds are locked.
* `Delivered` — Collector has confirmed delivery.
* `Disputed` — Collector or artisan has raised a dispute.
* `Paid` — Funds have been released to the artisan.
* `Refunded` — Funds have been returned to the collector.

## Main Functions

### `createCommission()`

Creates a commission and locks ETH in the escrow contract.

```solidity
createCommission(
    address artisan,
    address arbiter,
    uint256 deadline
)
```

### `confirmDelivery()`

Allows the collector to confirm that the commissioned work has been delivered.

### `releasePayment()`

Releases the locked funds to the artisan after delivery confirmation.

### `refundAfterDeadline()`

Allows the collector to recover the locked funds after the deadline if delivery has not been confirmed.

### `raiseDispute()`

Allows either the collector or artisan to raise a dispute while the commission is funded.

### `resolveDispute()`

Allows only the designated arbiter to resolve a dispute by either paying the artisan or refunding the collector.

## Technology Stack

* **Solidity ^0.8.24**
* **Foundry**

  * Forge
  * Anvil
* **OpenZeppelin Contracts**
* **GitHub Actions** for automated testing

## Project Structure

```text
secure-money-locker/
├── .github/
│   └── workflows/
│       └── test.yml
├── src/
│   └── CommissionEscrow.sol
├── test/
│   └── CommissionEscrow.t.sol
├── lib/
│   ├── forge-std/
│   └── openzeppelin-contracts/
├── foundry.toml
├── foundry.lock
├── .gitignore
├── .gitmodules
└── README.md
```

## Installation

Clone the repository:

```bash
git clone https://github.com/nikitabiradar231/secure-money-locker.git
cd secure-money-locker
```

Install dependencies:

```bash
forge install
```

## Build

Compile the smart contract:

```bash
forge build
```

## Run Tests

Run the complete test suite:

```bash
forge test
```

### Test Results

The current test suite contains **7 tests**, covering:

* Commission creation and fund locking
* Preventing payment before delivery
* Payment after delivery
* Refund after deadline
* Arbiter dispute resolution
* Arbiter authorization
* Preventing duplicate payment

Current result:

```text
7 passed
0 failed
0 skipped
```

## Formatting

Check Solidity formatting:

```bash
forge fmt --check
```

Automatically format Solidity files:

```bash
forge fmt
```

## Continuous Integration

This project uses **GitHub Actions** to automatically run the Foundry test suite.

The workflow is located at:

```text
.github/workflows/test.yml
```

Every push to the repository can trigger automated contract testing.

## Security

The contract uses OpenZeppelin's `ReentrancyGuard` to protect functions that transfer ETH.

State changes are also performed before external ETH transfers to reduce reentrancy risk.

> **Disclaimer:** This project is intended for educational and development purposes and has not been professionally audited. Do not use it to hold real funds without an appropriate security audit.

## License

This project is licensed under the **MIT License**.
