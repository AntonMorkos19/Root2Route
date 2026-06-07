# Auction Hub & API Integration Guide

This document outlines the correct way for the mobile application to interact with the backend Auction Hub and API, especially after the latest concurrency improvements.

## 1. Connecting to the Auction Hub

The SignalR hub is located at the following endpoint:
`https://root2route.runasp.net/hubs/auction` (or your local equivalent).

### Best Practices:
* Ensure you are passing the authentication token if required by the hub.
* Enable automatic reconnection on the client side in case of network drops.

## 2. Managing Auction Groups

To receive real-time updates for a specific auction, the user must join that auction's dedicated group using the auction's unique `Guid`.

*   **Join a Group:**
    Invoke `JoinAuctionGroup(string auctionId)` when the user navigates to the auction details screen.
*   **Leave a Group:**
    Invoke `LeaveAuctionGroup(string auctionId)` when the user navigates away or closes the screen to avoid memory leaks and unnecessary network traffic.

## 3. Real-Time Events (Listening)

The hub pushes real-time updates to connected clients. You must register listeners for these events:

*   **`ReceiveNewBid`**
    *   **Arguments:** `(decimal newAmount, Guid bidderId)`
    *   **Action:** When triggered, update the UI to reflect the new highest bid and show who the highest bidder is.

## 4. Retrieving the Current Auction State

If a user gets disconnected and reconnects, or simply loads the screen for the first time, you can fetch the live state directly from the hub without needing an HTTP API call:

*   **Method:** `GetAuctionState(Guid auctionId)`
*   **Returns:** An object containing:
    ```json
    {
      "currentHighestBid": 150.50,
      "highestBidderId": "guid-of-the-bidder"
    }
    ```

## 5. Placing Bids & Concurrency Handling

Bids are placed via the standard HTTP REST API endpoint (`POST /api/v1/auctions/{auctionId}/bid`).

> [!IMPORTANT]
> **Handling "Due to high bidding volume" Errors (400 Bad Request)**
> 
> The backend now strictly enforces **Optimistic Concurrency**. If two users try to bid on the same item at the *exact same millisecond*, the database will accept one and reject the other to prevent data corruption.
> 
> The backend will automatically retry processing the bid a few times. If the conflict persists (meaning someone else successfully placed a higher bid during that split second), the API will return a `400 Bad Request` with the message:
> `"Due to high bidding volume, your bid could not be processed. Please try again."`
> 
> **Mobile App Action:**
> Do NOT crash or show a generic error. Catch this specific message and prompt the user: *"Another user just placed a bid! The price has changed. Please review the new price and try again."* The SignalR `ReceiveNewBid` event will arrive simultaneously, so your UI should automatically update with the new price.
