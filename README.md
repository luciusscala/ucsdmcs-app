# Fixture by SLLAB

Fixture is an IOS app built for college club sport teams to keep track of practice/game availability and manage rosters. It is part of a bigger project ( ADD LINK ) which aims to create an affordable platform to allow clubs to run smoother and be more competitive. In Fixture, players can see their schedule and mark their availability for practices, games, tournaments, and social events. Captains can create events, track attendance, and message the team.

## Requirements

- Xcode 26
- iOS 18.6 or later

## Getting Started

1. Clone the repo and open `ucsdmcs.xcodeproj`.
2. Xcode resolves the Swift package dependencies ([supabase-swift](https://github.com/supabase/supabase-swift)) automatically.
3. Select your development team under **Signing & Capabilities**, then build and run.

## Project Structure

```
ucsdmcs/
├── Models/       Data types (events, teams, roster, availability)
├── Services/     Supabase client, website API, Keychain, deep links
├── Views/        App screens; Admin/ holds captain-only views
├── Components/   Reusable UI pieces
└── Theme/        Shared colors and styles
```
*note: in the codebase you may notice that the app is referred to as ucsdmcs; this is the original name of Fixture by SLLAB and is often used interchangeably throughout.*

## Backend

- **Supabase** stores teams, rosters, events, and availability.
- **Website API** (`www.ucsdmcs.com/api`) handles captain unlock and SMS reminders.
- **Universal Links** (`app.ucsdmcs.com/events/<id>`) open events directly in the app.

## AI Disclosure

Parts of this codebase and readme were written with the help of AI. All files were reviewed by a human, but it is provided as-is, with no guarantee that it is correct, secure, or fit for any particular purpose.
