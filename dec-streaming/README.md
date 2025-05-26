# 📺 STREAMVAULT PLATFORM

**StreamVault** is a fully decentralized media streaming ecosystem built on the Stacks blockchain using the Clarity smart contract language. It provides robust support for content monetization, priority queue management, detailed platform analytics, and user subscription systems.

---

## 🚀 Features

- 🔐 **User Management**
  - Register Basic and Premium users
  - Subscription tier system with expiration and renewal
  - Credit-based access for premium content

- 🎬 **Content Catalog**
  - Upload premium and free content
  - Track views, earnings, categories, and availability
  - Creator revenue system with dynamic earnings allocation

- 📊 **Platform Analytics**
  - Global stats: users, sessions, content, revenue
  - Per-content analytics: views, earnings, category, etc.

- 💰 **Advanced Monetization**
  - Per-view pricing for premium content
  - Creator royalty pool (70% share per view)
  - Platform revenue tracking
  - In-app credit purchase mechanism

- 📦 **Streaming Engine**
  - Start and end streaming sessions with duration tracking
  - Quality selection and cost deduction for streams

- 🧾 **Content Queues & Playlists**
  - Add content to user queues with priority tagging
  - Create and manage custom playlists (up to 50 items)

- ❤️ **Favorites**
  - Save favorite content for quick access

- 🛠️ **Moderation Tools**
  - Content reporting system with reason logging
  - Auto-disable flagged content pending review

---

## 📁 Smart Contract Structure

- `platform-users` — Maps users to profiles and subscriptions
- `content-catalog` — Tracks uploaded content metadata
- `streaming-sessions` — Stores active and past sessions
- `content-queue`, `user-queues`, `user-playlists`, `user-favorites` — Personalized content interactions
- `creator-earnings`, `monthly-revenue` — Tracks payouts and earnings

---

## 📜 Key Constants

| Constant | Description |
|---------|-------------|
| `PREMIUM-TIER`, `BASIC-TIER` | Subscription levels |
| `MAX-PLAYLIST-SIZE`, `MAX-QUEUE-SIZE` | Per-user limits |
| `SESSION-DURATION` | Default stream session length (seconds) |

---

## ⚙️ Functions Overview

### ✅ Public Functions

- `register-premium-user`, `register-basic-user`
- `upload-premium-content`, `upload-free-content`
- `start-premium-stream`, `end-stream-session`
- `purchase-credits`, `renew-subscription`
- `add-to-priority-queue`, `add-to-favorites`
- `create-custom-playlist`
- `report-content`

### 📖 Read-only Functions

- `get-user-profile`, `get-content-details`, `get-session-info`
- `get-user-playlist`, `get-user-queue`, `get-user-favorites`
- `get-content-analytics`, `get-platform-analytics`
- `check-subscription-valid`

---

## 🧪 Error Codes

| Code | Error |
|------|-------|
| `u100` | Not Authorized |
| `u101` | User Exists |
| `u102` | User Not Found |
| `u103` | Content Not Found |
| `u104` | Session Not Found |
| `u105` | Playlist Full |
| `u106` | Content Unavailable |
| `u107` | Insufficient Credits |
| `u108` | Queue Full |
| `u109` | Subscription Expired |
| `u110` | Invalid Payment |

---

## 📦 Deployment

To deploy on the Stacks blockchain:
1. Install [Clarinet](https://docs.stacks.co/clarity/clarinet)
2. Run `clarinet check` to validate contract syntax
3. Use `clarinet deploy` to publish to your devnet/testnet

---

## 🧠 Future Enhancements

- Token-based payments via SIP-010 integration
- Moderator DAO for content validation
- Live streaming support
- NFT-based subscription perks
