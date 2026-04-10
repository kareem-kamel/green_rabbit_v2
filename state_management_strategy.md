# State Management Strategy

This document outlines the state management architecture for the Green Rabbit Trading App.

## 🟢 Use Riverpod for Data-Driven Features
Riverpod is the primary choice for features that involve data fetching, real-time updates, and asynchronous logic.

| Feature            | Implementation Approach | Notes                                    |
|--------------------|-------------------------|------------------------------------------|
| **Market**         | `StreamProvider`        | Live prices via WebSocket integration.  |
| **Charts Data**    | `StreamProvider`        | Real-time chart updates.                 |
| **Watchlists**     | `StateNotifier`         | Managing add/remove stock actions.       |
| **News + AI**      | `FutureProvider` / `AsyncNotifier` | Handling API calls for news articles and AI insights. |
| **Notifications**  | `StreamProvider`        | Displaying real-time notifications.      |
| **Comments**       | `StateNotifier`         | Managing user comments on instruments.    |

---

## 🔴 Use Cubit/Bloc for Event-Driven & App-Wide Features
Cubit/Bloc is reserved for complex state transitions, event-driven logic, and critical application flows.

| Feature            | Implementation Approach | Flow/States                              |
|--------------------|-------------------------|------------------------------------------|
| **Auth**           | `Cubit`                 | `LoggedOut` → `Loading` → `LoggedIn` → `Error` |
| **Subscriptions**  | `Cubit`                 | `Idle` → `Processing` → `Active` → `Failed` |
| **Alerts**         | **`Bloc`**              | `PriceHit` → `Trigger` → `Notify` → `Done` (Event-driven) |
| **App Health**     | `Cubit`                 | Feature flags and system status.         |
| **App Config**     | `Cubit`                 | Environment switching (Dev/Prod).        |

---

## Key Principles:
1. **Separation of Concerns**: Use Riverpod for data delivery and BLoC for business processes.
2. **Reactivity**: Leverage `StreamProvider` for all real-time market data to ensure a responsive UI.
3. **Event-Driven Alerts**: Always use BLoC for Alerts to properly manage the complex event pipeline from price hits to user notification.
