# Dreamland
Dreamland is a new age AI+metaverse company and has a concept of games, where every user can play these games with AI agents and win DREAM tokens multiple times a day. A user can win upto 5 DREAM tokens on a single day.

DREAM tokens are a virtual currency and have a real monetary value. At the end of every hour, the tokens won by the user are converted to USD by calling a third-party API that provides the rate (for the assignment, we can hardcode to 15 cents per token).

Every time a user is issued a token and it gets converted to USD, there will be fees which we need to keep track of (the user will not bear the fees, but Dreamland will)

In the backend, there are double-entry accounting ledgers that keep track of a user's tokens, the current USD value and the fees.

Imagine you are building APIs for Dreamland:
1. API that accepts that a user has won some amount of DREAM token at a particular time of a day
1. API that returns the history of DREAM tokens a user has won for the current day so far
1. API that returns the history of USD amounts a user has won till now (till the previous day)
1. API that returns the stats: sum of tokens won on the current day so far and the total value of USD a user has in his account

Let's focus on the below for the design side of things:
1. Database table design given the APIs above
1. Database needs to have a solid double-entry ledger to track the tokens and USD (might make sense to read up about ledgers - some great sources here and here). Let's design ledgers for both the tokens and USD
1. Data types we can use for the ledger amounts
1. Edge cases - list some edge cases both in APIs and database that you will handle
1. Any other APIs and tools you can think of (no need to implement)
1. Infrastructure - This is a global system with customers across the world. Let's discuss more about setting up the infra, how to share data across different regions, how to solve for region-specific data for issues like GDPR, how to replicate some tables out of a region to a central cluster for analytics, etc. This is just a textual answer with maybe some design diagrams

## Checklist
- [ ] User can only win 5 tokens a day
- [ ] Every hour, tokens won by users are converted to currency using third party API
- [ ] Fee is charged for every conversion and is paid by Dreamland

## Edge Cases
## Useful tools
## High Level System Design

