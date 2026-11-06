<div align="center">

<sub>[Português](README.md) · **English**</sub>

<img src="docs/brand/assets/app-icon.svg" width="88" alt="Cajui icon: the cajuí, a fruit from the Brazilian Cerrado, in terracotta." />

# Cajui

**Manage your finances by chatting with the app.**

An Android personal-finance app with an AI assistant: you chat to record expenses, and the app reads statements and
receipts and answers with the month's numbers. It is a complete project built from scratch: specification, a Dart
domain, a Flutter app, a cloud server of my own and a design system with a published gallery.

<picture>
  <source media="(prefers-reduced-motion: reduce)" srcset="docs/media/extrato-pela-juju.png" />
  <img src="docs/media/demo.webp" width="320" alt="A 45-second demo of Cajui with made-up data: a shared bank statement opens in the conversation with Juju, who summarizes 12 movements; the Groceries block is checked with its lines open, the next blocks are confirmed, the bakery gets a category, a Pix to a person becomes 'someone in the household' and 9 entries are recorded at once. Then the camera moves to Home, the 3D carousel shows what is left, what comes in and what goes out, My month opens and the card wallet appears." />
</picture>

<sub>Recorded from the real app, running with made-up data. No number is real.</sub>

![CI](https://github.com/Marcos-Codfy/finance-cajui/actions/workflows/ci.yml/badge.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-Android-7F52FF?logo=kotlin&logoColor=white)
![Tests](https://img.shields.io/badge/tests-1%2C850-2E7D32)
![Domain coverage](https://img.shields.io/badge/domain-92.9%25-2E7D32)
![Cost](https://img.shields.io/badge/fixed%20cost-R%24%200.00-B33A16)

**[See the design system gallery live](https://cajui-teal.vercel.app/gallery/)**

[About](#overview) · [Architecture](#architecture) · [API documentation](docs/api.md) ·
[Decisions (32 ADRs)](docs/architecture/adr) · [Specification](docs/spec) · [Design system](packages/design_system) ·
[Security](docs/security) · [Wireframes](docs/design/wireframes.html)

<sub>The specification, the ADRs and the app itself are in Brazilian Portuguese.</sub>

</div>

---

**If you want to get to know the project:** [Overview](#overview) · [Screens](#screens-and-design-system) · [Architecture](#architecture) ·
[Problems and solutions](#technical-problems-and-solutions) · [Technologies](#technologies) · [Design patterns](#design-patterns-applied) ·
[Security](#security-and-privacy) · [Quality](#quality-and-tests) · [Problems found](#problems-found-and-fixes)<br />
**If you want to run it:** [How to run](#how-to-run-the-project) · [Scripts](#scripts) · [Structure](#project-structure) ·
[Publishing](#how-it-is-published)

## Overview

Cajui is an Android personal-finance app that I started to keep track of my household's bills, in place of a
spreadsheet that took work to maintain. The first version was the spreadsheet in app form, and I found filling everything in tiring. So I changed the focus: instead of screens to fill in, you chat with an assistant (Juju),
and the app uses what the bank already sends, such as notifications, statements and receipts. Today two phones share the
same data, synced, and there is a web page just for looking things up.

Besides being a personal tool, the project became my lab for learning and practicing software engineering for real:
MVVM, DDD (the business language and rules inside the domain), SOLID principles, clean architecture, dependency
injection and design patterns such as Factory, Strategy, Adapter, Repository, Observer and Singleton (here, the single
instances are handled by Riverpod's providers). The [patterns table](#design-patterns-applied) shows where each one
appears in the code, and the decisions are recorded in [ADRs](docs/architecture/adr).

**How it was built:** I wrote the specifications for what the app should do and built the project with Claude's help, as
a programming assistant. The Claude API is also used inside the app, in the conversation with Juju.

### What the app does

- **Entries by conversation.** You type or speak "spent 35 at the market", and the app creates the entry with a
  category and a payment method. You can undo it right after.
- **Questions about the month.** The assistant answers how much is left, what is due and how much is missing to close
  the month, using the app's own numbers.
- **Statement reading.** You share the statement's PDF or screenshot; the phone reads it page by page, and the
  conversation checks it in blocks before saving. Reading the same statement twice does not duplicate entries.
- **Bank notifications.** An approved purchase becomes an entry automatically, with an option to undo. When money comes
  in, the app asks you to confirm.
- **Receipts.** A photo, screenshot or PDF becomes an entry proposal for you to check. The text recognition happens on
  the device, and only text with personal data masked goes to the AI.
- **Two phones, the same data.** Entries sync between the devices, and the web look-up is protected by an authenticator
  code.
- **Explicit money rules.** A credit card is a way to pay, not an expense. A meal voucher is a separate currency that is
  not added to cash. Both rules live in the domain's types.

### Technical summary

| Area            | What was done                                                                                                  | Where to look |
| --------------- | -------------------------------------------------------------------------------------------------------------- | ------------- |
| Architecture    | Clean architecture by feature, MVVM with sealed state (Riverpod), Coordinator and centralized dependency injection; a custom checker verifies the layers | [ADR-001](docs/architecture/adr/ADR-001-monorepo-e-dominio-compartilhado.md), [002](docs/architecture/adr/ADR-002-estado-com-riverpod.md), [031](docs/architecture/adr/ADR-031-navegacao-com-coordinator.md) |
| Domain          | Dart shared by app and server; sealed `Result` and `Failure`; money as integer cents; numbered business rules, each with a test | [`packages/domain`](packages/domain) |
| AI              | Claude (Messages API, with *tool use*) behind a swappable interface; personal data masked before it leaves; every value the AI writes is checked | [ADR-010](docs/architecture/adr/ADR-010-integracao-com-a-deepseek.md), [021](docs/architecture/adr/ADR-021-assistente-que-age.md), [030](docs/architecture/adr/ADR-030-extrato-pela-juju.md) |
| Server          | Dart + Shelf, single executable, on Oracle Cloud (OCI), with TLS; encrypted, hash-chained event log; documented API | [`server/`](server), [`docs/api.md`](docs/api.md) |
| Design system   | Own package with tokens, components, 3D motion and sounds; a published gallery with the screen states | [`packages/design_system`](packages/design_system), [gallery](https://cajui-teal.vercel.app/gallery/) |
| Native Android  | Share intake, on-device OCR, bank notifications, home screen widget, reminders and voice input | [`app/android`](app/android) |
| Quality         | 1,850 tests, named after the rule they prove; 86% to 93% coverage per package; secret scan over the history | [`tool/`](tool), [quality-gates](docs/spec/quality-gates.md) |
| Process         | 32 ADRs, Conventional Commits, pull requests and CI on GitHub Actions | [`docs/architecture`](docs/architecture) |

### Two decisions that shaped the project

Two decisions shaped the rest. The first: the AI only reads and suggests; the domain does the math and applies the
rules, in Dart, used by both the app and the server. The second: in the statement conversation, Juju's sentences
are built by the app from the domain's numbers, not by the model, so what she says matches what the screen shows.

### How to use this repository

- **Run the app.** Clone the repository, run `flutter pub get` and `flutter run`. With no server configured, it works on
  its own on the device (see [How to run the project](#how-to-run-the-project)).
- **Connect it to a server of your own.** The server in [`server/`](server) runs on your machine with
  `scripts/servidor-local.ps1`; the app points to it through the `CAJUI_API_URL` and `CAJUI_ACCESS_KEY` variables. The
  AI key stays outside the repository.
- **Reuse the design system.** The [`packages/design_system`](packages/design_system) package depends on neither the app
  nor Riverpod, and the [gallery](https://cajui-teal.vercel.app/gallery/) shows every component in every state.
- **Reuse the domain.** The [`packages/domain`](packages/domain) package is plain Dart, with no Flutter (money, installments, card
  statements, the month's budget) and fits another app or server.
- **Study the decisions.** The [ADRs](docs/architecture/adr) explain the reason behind each choice, and the
  [API documentation](docs/api.md) describes every server route.

## Screens and design system

<p align="center">
  <img src="docs/media/extrato-pela-juju.png" width="960" alt="Three screens of the conversation with Juju: the statement summary and the Groceries block with Confirm, See the lines and Fix; the question about a Pix to a person, with the options It is an expense, Someone in the household, My own account and Do not record; and the end, with 9 entries saved and the Done and Undo all buttons." />
  <br /><sub>The statement with Juju: summary, blocks by category, one question at a time and the whole batch with "Undo all".</sub>
</p>

<p align="center">
  <img src="docs/media/o-mes-na-mao.png" width="960" alt="Three screens: Home, with the 3D carousel of what is left this month and the Your money list; My month, with cash and voucher income kept apart and spending by group; and the credit card wallet." />
  <br /><sub>Home with the 3D carousel, My month with cash and voucher always apart, and the card wallet.</sub>
</p>

<p align="center">
  <img src="docs/media/design-system.png" width="960" alt="The design system gallery in the browser: foundation, components, depth, screens and senses in the menu, and the Conversation page with Juju's message, the user's message and a message with a list of purchases and buttons." />
  <br /><sub>The design system gallery: every component, state and screen of the app, browsable, with sound and a dark
  theme · <a href="https://cajui-teal.vercel.app/gallery/">see it live</a> · <a href="packages/design_system">its README</a></sub>
</p>

<p align="center">
  <img src="docs/media/design-system/widget-chegada.webp" width="260" alt="The glass widget on the home screen, over an aurora of light, with the month's leftover and two shortcuts; tapping the number opens the app growing out of the widget, and the Home numbers arrive through the glass." />
  <br /><sub>The glass widget and the arrival in the app, recorded in the gallery with made-up numbers.</sub>
</p>

## Architecture

Clean architecture, organized by feature (`features/<x>/{application,infrastructure,presentation}`).
`composition.dart` is the only place that binds a port to an adapter, and no math lives in the app: it asks the domain.

```mermaid
flowchart LR
  subgraph PHONE["Android phone"]
    UI["Flutter screens<br/>ViewModels with sealed state"]
    APP["Use cases<br/>(application)"]
    NAT["Kotlin<br/>OCR · notifications · widget"]
    LOG[("Local data<br/>encrypted events")]
  end
  DOM["Domain<br/>Dart"]
  subgraph VM["Server (VM)"]
    API["Shelf API"]
    STORE[("Event log<br/>AES-256-GCM + SHA-256")]
    AI["AI reading<br/>masking and schema"]
  end
  WEB["Web<br/>look-up mode"]
  DS["AI (Claude)"]

  UI --> APP --> DOM
  NAT --> APP
  APP --> LOG
  APP -- "entries + access key" --> API
  WEB --> API
  API --> DOM
  API --> STORE
  API --> AI --> DS
```

**How a statement becomes entries**, from the moment you share it to the moment it is saved:

```mermaid
sequenceDiagram
  participant Y as You
  participant C as Phone
  participant S as Server
  participant I as AI
  Y->>C: shares the statement's PDF
  C->>C: reads each page with OCR and rebuilds the lines
  C->>C: recognizes the statement and hides names, CPF and account
  loop for each page
    C->>S: sends the lines, with the personal data already hidden
    S->>I: asks for the page's transactions
    I-->>S: returns the transactions as JSON
    S-->>C: passes on only those that pass validation and whose amount is written in the text
    C->>C: asks again for dated lines with an amount that went missing
  end
  C->>Y: shows the summary, the blocks by category and the questions
  Y->>C: confirms ("Record it")
  C->>S: saves the batch, with keys built from the content (nothing duplicates)
```

More in the [ADRs](docs/architecture/adr): [030](docs/architecture/adr/ADR-030-extrato-pela-juju.md) covers the
statement, [020](docs/architecture/adr/ADR-020-chave-da-casa.md) access, and
[022](docs/architecture/adr/ADR-022-a-ia-le-a-foto.md) the photo read by the AI.

### Flutter app

The app is Flutter, in clean architecture organized by feature: each one has `application` (use cases),
`infrastructure` (adapters) and `presentation` (screens and ViewModels).

- **MVVM with sealed state.** The screen only draws; the ViewModel is a Riverpod `Notifier`, and the state is a sealed
  hierarchy, so an exhaustive `switch` makes a new state without a design fail to compile.
- **Navigation by Coordinator.** Each feature has a coordinator over the `SceneNavigator` port: the screen says what the
  person tapped, and the coordinator decides which scene to open. A ViewModel never navigates.
- **Centralized dependency injection.** Every dependency (repositories, services, adapters) is registered in one file,
  `composition.dart`. An automatic checker stops an inner layer from importing an outer one. Business rules do not live
  in the app: it asks the domain.
- **Offline first.** The data lives on the device, encrypted, as an event history (each entry is an event), and syncs when there is network.
- **Look and feel only through the design system.** Colors, typography, spacing and animation durations come from the
  design system package, never from the screens' code. The app uses `WidgetsApp` instead of `MaterialApp` so it does
  not inherit Material's look, and an automatic check blocks any color or style defined directly in a screen.

### Server

A single Dart (Shelf) executable running on a VM on **Oracle Cloud Infrastructure (OCI)**, on the free tier, behind a
proxy with automatic TLS and managed as a system service. What it does:

- **Stores the data as an event log.** Each event is encrypted with AES-256-GCM and chained by SHA-256, so any change
  to the past is detected. There are per-file summaries and a daily encrypted backup, copied off the machine.
- **Validates everything that arrives.** JSON is read strictly (an extra, missing or wrong-type field is refused), the
  domain rules are checked again on the server, and every error carries a code from a catalog of 47.
- **Authenticates.** The device signs in with an access key, a random secret shared by the phones of the same household (called the "house key" in the project); the server keeps only the hash and compares in constant
  time). The web look-up signs in with an authenticator code (TOTP, RFC 6238), which opens a 30-day read-only session,
  locked after five wrong attempts.
- **Protects.** Per-origin rate limiting, CORS for a single origin, and secrets in the service's encrypted credentials,
  never in the repository.
- **Talks to the AI** (next section) and returns only what passes the schema.

Every route is documented, with request, response and errors, in [`docs/api.md`](docs/api.md).

### Juju assistant and AI integration

Juju is a conversational assistant with ***tool use***: the server integrates Anthropic's Messages API (Claude) and
gives the model real tools: record an expense, cancel, list, record income, recategorize and pay down a debt. The
decisions worth telling:

- **The AI reads, the domain decides.** The model returns structured data; the domain does the math and applies the
  rules.
- **One port, several vendors.** The server only knows the `ChatClient` interface (Strategy pattern). There are adapters
  for Claude and for DeepSeek, chosen by configuration, and a fake client in the tests.
- **Privacy before the AI.** Person names, CPF numbers and accounts are masked on the phone, before the text leaves it.
- **The AI's answer is untrusted input.** Every amount in reais it writes is checked against the summary the server
  sent, the tools and the question. A value with no source goes back to the model once; if it insists, a fixed-format
  answer is returned.
- **Usage and failure controls.** There is a monthly token budget, a maximum time per call and a circuit breaker that
  stops calling the AI when it starts failing. If the AI is unavailable, the app tells you and you keep recording
  entries by hand.

### Sync between devices

The data is a history of facts (entries, corrections and cancellations). Every write request carries a unique
identifier: if the phone sends the same request again, for example after a network drop, the server recognizes it and
does not record it twice. The server only stores and returns; each phone does the math, with the same domain. The app
checks the top of the log every 20 seconds and downloads the data only when something changed. If the same card or
category is edited on both devices, the most recent edit wins, and a cancelled entry stays cancelled even if the other
device still shows it.

### Design system

The design system is a package of its own in Dart, [`packages/design_system`](packages/design_system), and the app is
its first user:

- **Centralized styles.** Colors, fonts, spacing, borders, shadows, animation timings and sounds live in one place and
  are used by the role they play (for example, "action button color"). Changing the color of every button means editing
  one line, and the contrast test runs right after.
- **Components.** Buttons, amounts in reais, cards, fields, notices, chat bubbles, the month's rings and timeline, a 3D
  credit card, glass panels, a carousel and a card stack. Each one appears in all of its states.
- **Animation and sound.** A depth effect when scrolling, transitions between screens and one sound for each kind of
  control. Animation has three intensity levels and respects the system's "reduce motion" setting.
- **Accessibility.** Computed and tested color contrast, touch targets of at least 48 dp, support for enlarged fonts
  and for screen readers.
- **Gallery.** A [sample site](https://cajui-teal.vercel.app/gallery/) with every component, every app screen in its
  states and the design decisions, with a dark theme and sound and animation options.

### Native modules (Android)

The Kotlin modules cover what Flutter doesn't reach: receiving image, PDF and text shares; on-device OCR with ML Kit
(the PDF is rasterized by Android itself); reading the banks' notifications; the glass home screen widget; due-date
reminders; voice input (speaking instead of typing); and the device key kept in the Keystore.

## Technical problems and solutions

Each item describes the problem, the solution and the result.

### 1. Reading a whole statement without duplicating entries

- **Problem:** a monthly statement has dozens of lines, and the first version read only the first 30. On top of that,
  reading the same statement twice, or undoing and recording again, could not create duplicate entries.
- **Solution:** the phone sends the statement to the AI page by page (`POST /v1/statements/read-part`), and the AI only
  reads the text. The sentences of the conversation are built by the app ([`StatementDigest`](packages/domain/lib/src/statements/statement_digest.dart), [`StatementWords`](packages/domain/lib/src/statements/statement_words.dart)). To avoid
  duplicates, each saved line gets an identifier calculated from its content, not from its position on the page
  ([`StatementLineKey`](packages/domain/lib/src/statements/statement_line_key.dart)), plus a stamp that identifies that entry. When reading a statement, the app compares each line with
  what is already saved, one by one, by amount, day and name ([`StatementMatches`](app/lib/src/features/statements/application/statement_matches.dart)), and marks the repeated ones as "already in
  Cajui".
- **Result:** reading the same statement again shows "already in Cajui". Two identical purchases at the same bakery stay
  two, because each one matches its own statement line. And "Undo all" followed by "Record" saves the entries again,
  with identifiers that have not been cancelled.

### 2. OCR that scrambles tables

- **Problem:** in the first test on the phone, the line "Restaurante Sabor" showed up with the supermarket's amount. ML
  Kit (Google's OCR) returns text in blocks, and on a table-shaped page each column becomes a separate block. The OCR
  also sometimes breaks a number ("+3.120,,00", "-32, 80"), and the server dropped those lines without warning.
- **Solution:** the native code regroups each page's text into rows, by the vertical position of the pieces
  ([`TextRows.kt`](app/android/app/src/main/kotlin/app/cajui/capture/TextRows.kt)); the domain repairs the broken numbers ([`OcrLine`](packages/domain/lib/src/statements/ocr_line.dart)); and the phone checks the AI's answer: if a line with
  a date and an amount was not cited, it is requested again, and whatever is still missing is reported to the user
  ([`MissedLines`](app/lib/src/features/statements/application/missed_lines.dart)).
- **Result:** no line disappears without notice. The cases found on the phone became tests, using the exact lines the
  OCR read.

### 3. Card and meal voucher: money rules in the domain

- **Problem:** in the spreadsheet I used, a card purchase counted in the month it was made, not in the month of the
  bill, and the meal voucher was not treated as money. An app that adds everything into one total gets the whole month
  wrong.
- **Solution:** every monthly amount is a `TenderAmounts`, which keeps cash and voucher in separate fields; no operation
  adds the two. The card bill is a computed view, never an entry, and an installment purchase becomes a commitment in
  the debts list, one installment at a time.
- **Result:** the compiler rejects the wrong sum. A bill payment that shows up on a statement is marked "doesn't count",
  so the same expense is not counted twice.

### 4. Protecting personal data before the AI

- **Problem:** statements and receipts carry the name of whoever received the Pix, the tax ID and the account number.
- **Solution:** masking runs on the phone, before anything is sent ([`PiiRedactor`](packages/domain/lib/src/receipts/pii_redactor.dart), [`TransferLine`](packages/domain/lib/src/statements/transfer_line.dart)). The real name stays on the
  device and only appears in the question asked to the user ("Pix para Carla M Souza"). The AI's answer goes through a
  closed schema of fields, and every amount must be written in the text that was sent. Saved answers that mention a
  person are never used as examples for the AI.
- **Result:** the AI receives "PIX ENVIADO [NOME] 150,00", and the phone shows the name. A test suite of malicious
  receipts tries to inject instructions into the text (*prompt injection*).

<details>
<summary><b>5 more problems: sync, a code checker, screen transitions, sound and the glass widget</b></summary>

### 5. Syncing two phones

- **Problem:** two phones use the same accounts, and each one sometimes records without internet.
- **Solution:** the data is an event log: nothing is deleted, and fixing or cancelling adds a new event. Identifiers are
  born from the content, and if the same thing is edited on both sides, the most recent edit wins ([ADR-019](docs/architecture/adr/ADR-019-dois-aparelhos-um-livro.md)). With the
  app open, each device asks the server every 20 seconds for a number that only changes when the data changes
  ([ADR-024](docs/architecture/adr/ADR-024-sincronia-ao-vivo-e-auth-simples.md)).
- **Result:** what one phone records shows up on the other within seconds, and downloading the data again never
  duplicates anything.

### 6. Code rules checked automatically

- **Problem:** a clean architecture kept only by agreement falls apart at the first tight deadline.
- **Solution:** a custom checker built on `package:analyzer` ([`tool/code_metrics`](tool/code_metrics)) runs before every commit and in CI. It rejects
  an import that goes from an outer layer to an inner one, a file over 300 lines, a function over 30, more than 3 levels
  of nesting, two public types in one file, and a color written directly in a screen.
- **Result:** every file is checked on each commit, and none goes over the limits. Changing the color of every button
  means changing one value in the design system.

### 7. A transition that showed two screens at once

- **Problem:** when a screen opened, the previous one stayed visible under the new one for a few frames.
- **Solution:** the transition between screens now uses a single linear clock ([`CameraMove`](packages/design_system/lib/src/motion/camera_move.dart)): the screen behind leaves
  completely before the new one enters.
- **Result:** checked on the phone with a screen recording, frame by frame, and protected by a test that fails with the
  old code.

### 8. Sounds that a phone speaker can actually play

- **Problem:** the chosen sounds came as MP3, with silence at the start and different volumes. On the phone they were
  barely audible even at full volume: a phone speaker hardly plays anything below 300–400 Hz, and the button click had
  99% of its energy between 150 and 300 Hz.
- **Solution:** I cut the leading silence and smoothed the start (2 ms) and the end of each sound. Then I wrote a
  mastering script ([`level_sounds.py`](tool/sound/level_sounds.py)) that creates harmonics from the lows (the ear rebuilds the note), cuts the sub-bass and
  gently saturates each group of controls up to its target volume, measured the way the phone plays it (K-weighting, from
  ITU-R BS.1770). The origin and license of each file are in [`CREDITS.md`](packages/design_system/assets/CREDITS.md).
- **Result:** action buttons, cards, keys, switches and chips each have their own sound, defined as a design system
  item, and a test fails any sound that becomes too quiet for the speaker again.

### 9. A glass-effect widget on Android

- **Problem:** the home screen widget should look like glass, but Android draws widgets in another process
  (`RemoteViews`), with no wallpaper blur, no shaders and no animation of its own.
- **Solution:** the background is an "aurora" of diffuse light, made of layers of radial gradients, and the glass is a
  translucent film with a rim of light: it looks frosted because what is behind it has no defined edges. The widget's
  root is marked as `@android:id/background`, which makes Android 12 or newer open the app growing out of the widget.
  Inside the app, the `widget` route plays the arrival animation ([`CajuiGlassArrival`](packages/design_system/lib/src/motion/cajui_glass_arrival.dart)), in which the Home numbers come through the
  glass with the aurora lit behind them.
- **Result:** the same composition exists as design system components (`CajuiAurora`, `CajuiGlassPanel`, `CajuiOrb`),
  and the gallery shows the whole gesture, from the tap on the widget to the arrival in the app.

</details>

## Technologies

| Layer             | Technologies                                                                                    |
| ----------------- | ----------------------------------------------------------------------------------------------- |
| App               | Flutter 3.47 (Android to use, web to look things up), Riverpod 3 with sealed state, Dart 3.13   |
| Native (Android)  | Kotlin: share intake, on-device OCR with ML Kit, notification reading, widget, reminders        |
| Domain            | Dart, no Flutter and no `dart:io`: the same code on the phone and on the server            |
| Server            | Dart + Shelf, compiled to a single executable, on an Oracle Cloud (OCI) VM, with a TLS proxy and a system service     |
| Data              | Event log encrypted with AES-256-GCM and chained with SHA-256, daily backup                     |
| AI                | Claude (Messages API, with tools) or DeepSeek, behind the same `ChatClient` port                         |
| Design system     | Own package with tokens, components, glass, 3D motion and sounds; gallery published on Vercel   |
| Quality           | `very_good_analysis`, custom checker, per-package coverage floors, secret scanning              |
| Pipeline          | GitHub Actions, Conventional Commits, Vercel for the web                                        |

## Design patterns applied

Cajui is also my coursework for Mobile Development II, which asks for the app and the design system to follow the
patterns studied during the semester. The rule I followed was **one pattern per question**, never two for the same
thing.

| Question      | Pattern chosen                                                                     | Where                                                                                                                                                                                           |
| ------------- | ---------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| One screen    | MVVM: the page only draws, a Riverpod `Notifier` decides, the state is sealed      | [`entries_view_model.dart`](app/lib/src/features/ledger/presentation/entries_view_model.dart)                                                                                                   |
| The whole app | Layers (Clean), locked by a checker                                                | [`layer_rules.dart`](tool/code_metrics/lib/src/layer_rules.dart) · [ADR-001](docs/architecture/adr/ADR-001-monorepo-e-dominio-compartilhado.md)                                                 |
| Navigation    | Coordinator: the ViewModel says what happened, the Coordinator decides where to go | [`core/navigation`](app/lib/src/core/navigation) · [ADR-031](docs/architecture/adr/ADR-031-navegacao-com-coordinator.md)                                                                        |
| Dependencies  | Dependency injection with Riverpod, set up in a single file                        | [`composition.dart`](app/lib/src/app/composition.dart) · [ADR-002](docs/architecture/adr/ADR-002-estado-com-riverpod.md), [ADR-032](docs/architecture/adr/ADR-032-injecao-e-factory-de-cena.md) |
| Folders       | By feature: `features/<x>/{application,infrastructure,presentation}`               | one folder per scene                                                                                                                                                                            |
| Repository    | Monorepo of packages                                                               | [`packages/`](packages) · [ADR-001](docs/architecture/adr/ADR-001-monorepo-e-dominio-compartilhado.md)                                                                                          |

<details>
<summary><b>Architecture components and where they are in the code</b></summary>

| Component                           | In the code                                                                                                                                                                                                                                                                                                                          |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Core (models, repositories, `Result`) | [`packages/domain`](packages/domain) and [`packages/api_contract`](packages/api_contract)                                                                                                                                                                                                                                         |
| Design System                         | [`packages/design_system`](packages/design_system)                                                                                                                                                                                                                                                                                |
| Scene                                 | One folder per feature, with `application`, `infrastructure` and `presentation`                                                                                                                                                                                                                                                   |
| Scene factory                         | The Coordinator builds the page and the ViewModel's provider delivers the dependencies ([ADR-032](docs/architecture/adr/ADR-032-injecao-e-factory-de-cena.md))                                                                                                                                                                    |
| Coordinator                           | One per feature, in `presentation`, over the [`SceneNavigator`](app/lib/src/core/navigation/scene_navigator.dart) port: [`LedgerCoordinator`](app/lib/src/features/ledger/presentation/ledger_coordinator.dart), `BudgetCoordinator`, `CardsCoordinator`… ([ADR-031](docs/architecture/adr/ADR-031-navegacao-com-coordinator.md)) |
| View                                  | `*_page.dart`, only draws, with design system components                                                                                                                                                                                                                                                                          |
| ViewModel                             | `*_view_model.dart` (a `Notifier`), with the sealed state next to it                                                                                                                                                                                                                                                              |
| Server                                | The feature's port (`AssistantGateway`, `LedgerDownlink`…) and the HTTP adapter in `infrastructure`                                                                                                                                                                                                                               |
| Storage                               | `PreferencesStore`, `HouseholdKeyStore` and the event log, each with a real and an in-memory version                                                                                                                                                                                                                           |

</details>

<details>
<summary><b>Design patterns: examples in the code</b></summary>

| Pattern    | Example in the code                                                                                                                                                                                                                                                    |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Factory    | `factory of(...)` in [`home_view.dart`](app/lib/src/features/home/application/home_view.dart) and [`statement_view.dart`](app/lib/src/features/cards/application/statement_view.dart)                                                                               |
| Adapter    | [`NativeReceiptReader`](app/lib/src/features/receipts/infrastructure/native_receipt_reader.dart) fits Android's OCR into the `ReceiptReader` port; [`HttpAssistantGateway`](app/lib/src/features/assistant/infrastructure/http_assistant_gateway.dart) fits the API |
| Strategy   | [`ChatClient`](server/lib/src/ai/chat_client.dart) with [`DeepSeekChatClient`](server/lib/src/ai/deepseek_chat_client.dart) and [`ClaudeChatClient`](server/lib/src/ai/claude_chat_client.dart), chosen when the server starts                                      |
| Observer   | Riverpod's `ref.watch` in the pages and `Stream` in the live sync                                                                                                                                                                                                   |
| Repository | [`LedgerJournal`](app/lib/src/features/ledger/application/ledger_journal.dart), with local, remote and in-memory versions                                                                                                                                           |
| Result     | [Sealed `Result` and `Failure`](packages/domain/lib/src/shared/result.dart): a refused rule is a value, not an exception; [`Decoded`](packages/api_contract/lib/src/decoded.dart) does the same for a request that comes from outside                               |

</details>

**Class deliverables:**

| Deliverable                         | Where                                                                                                                                      |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| App theme                           | [Problem and audience](docs/spec/problem.md) and [brand](docs/brand)                                                                       |
| Screen prototype                    | [Low-fidelity wireframes](docs/design/wireframes.html): navigation map, 14 screens and the states                                          |
| Components and design system sample | [`packages/design_system`](packages/design_system) and the [live gallery](https://cajui-teal.vercel.app/gallery/), which is the sample app |
| API documentation                   | [`docs/api.md`](docs/api.md): every route with request, response and errors                                                                |

## Security and privacy

- **An access key** of 32 random bytes, generated on the installer's computer and compiled into the APK. The server
  keeps only its hash, in an encrypted systemd credential ([ADR-020](docs/architecture/adr/ADR-020-chave-da-casa.md)).
- **The web signs in with an authenticator code** (TOTP, RFC 6238), and that secret is also encrypted on the VM
  ([ADR-027](docs/architecture/adr/ADR-027-codigo-do-autenticador.md)).
- **The AI key exists only on the server**, never in the app, the web bundle or the repository. A scanner checks the
  tree **and the whole history** on every commit and every PR.
- **Data encrypted at rest:** each record with AES-256-GCM, chained with SHA-256. It is possible to prove nobody
  touched the past.
- **Masking before the AI, and the AI's answer treated as hostile input**, as in [problem 4](#4-protecting-personal-data-before-the-ai).
- A STRIDE threat model and an ASVS level 2 checklist live in [`docs/security`](docs/security). Where a control is
  **not** implemented, it says so.

## Quality and tests

| Item              | Status                                                                                                    |
| ----------------- | --------------------------------------------------------------------------------------------------------- |
| Tests             | **1,850**: app 611 · domain 493 · server 253 · design system 257 · contract 104 · gallery 81 · persistence 25 · checker 26 |
| Coverage          | contract 93.2% · domain 92.9% · persistence 91.5% · server 89.9% · design system 88.0% · app 86.4%       |
| Rule ↔ test       | Every rule has a number (`RN-xxx`) and a test with the same number. A numeric example in the spec becomes a test, to the cent |
| Texts             | Every error a person reads comes from a catalog of 47 codes, and the code that shows it is **generated** from it. A test per code makes sure no text goes out with an unfilled placeholder |
| Voice             | Banned terms ("déficit", "estourou", exclamation marks) are rejected by a test across every sentence in the app |
| Analyzer          | `very_good_analysis`, zero warnings                                                                       |
| Custom checker    | no size or layer limit broken                                                                                |
| Accessibility     | Lighthouse 100 on the web; semantics on from the root; the screen reader says who is speaking in the chat |

## Problems found and fixes

Real problems that showed up during development and what each one taught:

- **Tests passing, defect on the phone.** The statement reading passed hundreds of tests, but the first real PDF mixed
  up columns ([problem 2](#2-ocr-that-scrambles-tables)). Before that, the app read the API's error body in the wrong
  place, and the test did not notice because the fake server imitated what the app expected, not what the real server
  sends.
- **Installment purchase counted in full in the month it was made.** The domain already calculated it correctly, but a
  layer of the app added things up on its own instead of asking it. A core concept of the product was working wrongly.
- **Three error messages came out with a blank value.** A test that walks through every error code of the statement
  reading found three texts with an unfilled placeholder.
- **The web version had never run.** The `dart:io` HTTP client fails when created in the browser, and the app stopped
  before its first frame, with no error message.
- **An unreadable share closed the app on launch.** Any app can send an invalid file on purpose.

All of them were found in code review or in real use, and today each one has a test that covers the case.

## Operating cost

**R$ 0.00 fixed.** A free Oracle VM, Let's Encrypt TLS, free dynamic DNS, repository and pipeline on GitHub, and the
web on Vercel's Hobby plan. The only variable cost is the AI, billed per use: with DeepSeek it comes to **about R$ 0.60 a month** for 120
entries ([the math is here](docs/ops/ai-cost-estimate.md)); Claude costs more per token, and switching is only a
configuration change.

---

## Developer guide

### How to run the project

**Requirements:** Flutter 3.47 (with Dart 3.13), the Android SDK and an Android device or emulator. Python 3 only for
the pipeline's checkers.

```bash
git clone https://github.com/Marcos-Codfy/finance-cajui.git
cd finance-cajui
flutter pub get
cd app && flutter run
```

Without the access key compiled in, the app starts with no server and works on its own on the device. The key
(`CAJUI_ACCESS_KEY`) and the server address (`CAJUI_API_URL`) come in through `--dart-define` and are never versioned. The look-up
web build comes from `flutter build web --no-web-resources-cdn` inside `app/`.

### Scripts

| Command (PowerShell, from the root)    | What it does                                                                 |
| -------------------------------------- | ---------------------------------------------------------------------------- |
| `.\scripts\apk.ps1 -Release`           | Builds the APK and installs it on the phone on USB (key and server by environment variable) |
| `.\scripts\servidor-local.ps1`         | Runs the server on this machine, reading the AI key from outside the repo    |
| `dart run tool/code_metrics/bin/check.dart` | Runs the size and layer checker                                         |

<details>
<summary><b>Tests for each package</b></summary>

```bash
cd app && flutter test
cd packages/design_system && flutter test
cd packages/design_system/gallery && flutter test
cd packages/domain && dart test
cd packages/api_contract && dart test
cd packages/persistence && dart test
cd server && dart test
cd tool/code_metrics && dart test
```

</details>

### Project structure

<details>
<summary><b>Folder tree</b></summary>

```text
app/                      Flutter: Android to use, web to look things up
  lib/src/features/       assistant, statements, receipts, ledger, budget, cards, home, export, reminders…
  android/                Kotlin: share intake, OCR, notifications, widget, reminders
packages/
  domain/                 business rules in Dart
  api_contract/           DTOs, strict JSON reading, error catalog
  persistence/            encrypted event log with a hash chain
  design_system/          tokens, components, motion, sounds
    gallery/              the browsable design system sample
server/                   Dart + Shelf: API, AI reading, sync
tool/                     checkers: size, layers, secrets, coverage
docs/                     specification, ADRs, brand, security, cost and performance
scripts/                  APK, local server and web build
```

</details>

### How it is published

- **Server:** a single Dart executable (`dart compile exe`), built in the pipeline and served behind a TLS proxy. The
  operation of the machine (provisioning, service, backup) is not part of this copy; the decisions are in ADRs
  [003](docs/architecture/adr/ADR-003-backend-dart-shelf.md),
  [005](docs/architecture/adr/ADR-005-criptografia-em-repouso-e-dbtool.md) and
  [011](docs/architecture/adr/ADR-011-hospedagem-a-custo-zero.md).
- **Web:** Vercel publishes `main`: the read-only web at the root and the design system gallery at `/gallery/`, both
  built by [`scripts/web.sh`](scripts/web.sh).
- **App:** the APK is built and installed over USB, with the access key and the server address compiled in.

## Credits

- **Specification, design and development:** [Marcos Vinicius Muniz Arruda](https://github.com/Marcos-Codfy)
- **Fonts:** Fraunces and Geist (SIL Open Font License)
- **Touch sounds:** Pixabay, under the Pixabay Content License, processed in the project; the others are synthesized
  here ([origin of each file](packages/design_system/assets/CREDITS.md))
- **Icons and illustrations:** drawn in the project

## License

[MIT](LICENSE). Fonts and sounds have their own licenses, listed in the credits above.

---

<div align="center">

<sub>The name comes from the **cajuí** (<i>Anacardium humile</i>), the low-growing wild cashew of the Tocantins
Cerrado.</sub>

<sub>Made by <a href="https://github.com/Marcos-Codfy">Marcos Vinicius Muniz Arruda</a> · Palmas, Brazil · 2026</sub>

</div>
