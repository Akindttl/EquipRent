# ⚡ EquipRent

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Stacks](https://img.shields.io/badge/Built%20on-Stacks%20Blockchain-orange)
![Smart Contracts](https://img.shields.io/badge/Powered%20by-Clarity%20Smart%20Contracts-blue)
![Contributions](https://img.shields.io/badge/Contributions-Welcome-brightgreen)

*A decentralized peer-to-peer equipment rental marketplace with **escrow-secured rentals**, **dispute resolution**, and a **reputation system** — built on Stacks blockchain using Clarity.*

EquipRent is your **trustless rental ecosystem**, where **owners** safely monetize idle equipment, and **renters** gain secure, verifiable access — from tools and cars to heavy machinery.

---

## 🌟 Why EquipRent?

Traditional rental platforms suffer from:
❌ High platform fees
❌ Centralized dispute resolution (biased, slow)
❌ Fraud risks and non-returned deposits
❌ Lack of transparent reputations

✅ **EquipRent solves this** with:

* Blockchain-enforced **escrow protection**
* Automated **smart contract rental flows**
* **Transparent dispute resolution** built into code
* A **decentralized reputation system**

---

## ✨ Key Features

* 🔐 **Decentralized Equipment Registration**
  Owners register equipment with metadata: description, location, availability, and rental rates.

* 💰 **Secure Escrow System**
  STX funds (rental fee + security deposit) are locked in smart contract escrow until completion.

* 🔄 **Transparent Rental Lifecycle**
  Full on-chain workflow: *Requested → Approved → Active → Completed*.

* ⚖️ **Automated Dispute Resolution**
  The `resolve-dispute` function allows third-party or admin intervention with flexible fund distribution.

* ⭐ **Reputation & History**
  On-chain profile tracking for owners and renters: reputation, earnings, expenses, and rental count.

---

## 🛠 Contract Architecture

### 🔑 Constants & Variables

* `CONTRACT_OWNER` → Contract deployer (receives platform fees).
* `PLATFORM_FEE_PCT` → e.g. `u5` (5%).
* `SECURITY_DEPOSIT_PCT` → e.g. `u20` (20%).
* `next-equipment-id` → Unique equipment IDs.
* `next-rental-id` → Unique rental IDs.

### 📦 Data Maps

* `equipment` → Equipment details per listing.
* `rentals` → Rental agreements + status.
* `user-profiles` → Reputation + rental history.
* `rental-escrow` → Active escrow balances.

### 🌐 Public Functions

* `register-equipment`
* `request-rental`
* `approve-rental`
* `complete-rental`
* `resolve-dispute`

### 🧩 Private Helpers

* `calculate-total-cost`
* `calculate-platform-fee`
* `get-days-between`
* `update-user-stats`

---

## 🚀 Getting Started

### 📋 Prerequisites

* [Stacks CLI](https://docs.stacks.co/)
* A funded Stacks wallet with STX tokens
* Familiarity with Clarity smart contracts

### 🛠 Installation

```bash
# Clone the repo
git clone https://github.com/your-username/equiprent.git

# Navigate into project
cd equiprent

# Deploy to local testnet
clarinet deploy
```

### 🔗 Deployment (Stacks Testnet)

1. Configure your wallet keys.
2. Deploy via `clarinet console` or directly with `stx deploy`.
3. Interact using Clarity console or frontend integration.

---

## 🔄 Rental Workflows

### ✅ Standard Flow

1. 🏗 Owner → `register-equipment`
2. 👤 Renter → `request-rental` (escrow locks funds)
3. 🛡 Owner → `approve-rental`
4. 🔓 Either → `complete-rental` (funds released, deposit returned)

### ⚖️ Dispute Flow

1. 🚩 Renter/Owner raises dispute
2. 👨‍⚖️ Resolver → `resolve-dispute` with % split
3. 💸 Escrow funds redistributed

---

## 🧪 Example Usage

### Register Equipment

```clarity
(contract-call? .equiprent register-equipment
  "Excavator - Model X"
  u500    ;; daily rate in STX
  "Lagos, Nigeria"
)
```

### Request Rental

```clarity
(contract-call? .equiprent request-rental
  u1        ;; equipment ID
  20250819  ;; start date
  20250822  ;; end date
)
```

### Approve Rental

```clarity
(contract-call? .equiprent approve-rental u1)
```

---

## 📊 Reputation System

Each user builds reputation automatically:

* 🟢 Successful rentals → +score
* 🔴 Disputes / cancellations → -score
* 📜 All history is publicly verifiable

This encourages **trust, accountability, and fairness** in the ecosystem.

---

## 🤝 Contribution Guide

We welcome contributions!

1. Fork the repo
2. Create a feature branch → `git checkout -b feature/your-feature`
3. Commit changes → `git commit -m "Add: your feature"`
4. Push branch → `git push origin feature/your-feature`
5. Submit a Pull Request 🚀

---

## 📜 License

This project is licensed under the **MIT License**.
See the full text in [LICENSE](./LICENSE).

---

## 📡 Roadmap

* [ ] 🖼 NFT integration for equipment identity
* [ ] 📱 Mobile dApp frontend (React + Stacks.js)
* [ ] 🤖 Automated arbitration system
* [ ] 🌍 Global multi-language support

---

## 👥 Community & Support

* 💬 Join our [Discord](https://discord.gg/stacks)
* 🐦 Follow [Stacks Twitter](https://twitter.com/stacks)
* 📖 Read the [Docs](https://docs.stacks.co/)

