# AIMF — Architecture

AIMF (Andrew Inbound Message Format, v1.9) as it is today: a small,
documented format for sending information **into** Andrew's
assistant from outside — by a person, or by another AI acting for
them. The format is the security: an allowlist, a strict schema,
and a tiny vocabulary of message types; anything else is shown to
Andrew as data, never treated as instructions, and nothing inbound
is ever acted on outbound without his approval. The canonical
source is the GitHub repo (`SPEC.md` is the protocol); the invite
page at **aimf.andrewdhorowitz.com** (Cloudflare Pages) is the
human front door, with the GitHub Pages page kept as a mirror whose
canonical tag points at the subdomain. Bots read the raw repo
files. The page carries GTranslate and a Cloudflare Web Analytics
beacon. No email addresses or private identifiers appear here.

This file is the canonical diagram source: it renders natively on
GitHub, and the interactive page beside it is generated from the
same Mermaid source — there is no second, hand-maintained copy.

**Canonical pattern (v3, adopted Oct 28, 2026):** three views —
System Context (L1), Container (L2), and a Deployment / host view —
with shapes keyed to the kind of thing (legend under the Deployment
view) and hosts drawn as their own deployment nodes. An interactive,
draggable rendering of the Deployment view lives beside this file at
[docs/interactive-architecture.html](interactive-architecture.html):
dragging there explores the view and never changes this source.

## Level 1 — System Context

Who takes part in AIMF, and which outside systems it touches.

```mermaid
C4Context
    title AIMF - System Context (protocol v1.9)

    Person(owner, "Andrew", "Protocol owner. Reviews every inbound attempt and approves every agreement and action.")
    Person(bot, "External AI / bot", "A counterparty: another AI (or a person) acting under an agreement. Reads the spec, onboards by trial, sends structured messages.")
    Person(visitor, "Human visitor", "Reads the invite page; may point their own AI at the protocol.")

    System(aimf, "AIMF - Inbound Message Format", "A documented envelope format with hard gates (allowlist, schema, message types) for sending information into Andrew's assistant.")

    System_Ext(gh, "GitHub", "Canonical repo: the spec, trial prompt, and test vectors. If it isn't in the repo, it isn't an update.")
    System_Ext(cf, "Cloudflare Pages", "Serves the canonical invite page at aimf.andrewdhorowitz.com.")
    System_Ext(transport, "Message Transports", "Email, a shared Drive folder, or a designated chat. The same envelope rides all three.")
    System_Ext(muse, "Muse - assistant side", "Runs the report-only attempt monitor the spec requires (section 10) and surfaces validated messages to Andrew.")

    Rel(visitor, aimf, "Reads the invite page")
    Rel(bot, aimf, "Reads the spec, onboards, sends messages")
    Rel(aimf, gh, "Spec and page are published from the repo")
    Rel(gh, cf, "Deploys the invite page")
    Rel(bot, transport, "Sends envelope messages")
    Rel(transport, muse, "Messages arrive for review")
    Rel(muse, owner, "Reports attempts; validated messages shown as data")
    Rel(owner, aimf, "Approves agreements and any action")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

## Level 2 — Container

The repo is the system: the spec, the trial prompt, and the test
vectors are the protocol, and the invite page is its front door.
Beside it, one assistant-side job does the monitoring the spec
itself requires.

```mermaid
C4Container
    title AIMF - Container View (protocol v1.9)

    Person(owner, "Andrew", "Reviews attempts; approves agreements.")
    Person(bot, "External AI / bot", "Counterparty under an agreement.")
    Person(visitor, "Human visitor", "Reads the invite page.")

    Container_Ext(transport, "Inbound Transports", "Email / shared Drive folder / designated chat", "Any of the three carries the same envelope: subject or filename names the type, body carries the message.")
    Container_Ext(gt, "GTranslate", "Hosted widget", "Automatic translation of the invite page.")
    Container_Ext(wa, "Cloudflare Web Analytics", "Beacon script", "Page-level counts for the subdomain.")

    System_Boundary(aimf, "AIMF") {

        Boundary(repo, "GitHub repo - canonical source", "andrewdhorowitz/aimf-protocol") {
            Container(spec, "Protocol Spec (SPEC.md)", "Markdown document - repository", "The format itself: the envelope, the gates (sender binding, schema, message types), agreements, update rules, and the monitoring duty. Version 1.9.")
            Container(trial, "Trial Prompt", "Markdown document - repository", "One self-contained prompt that turns any AI chat into a trial counterparty: simulate first, one real send only with its human's permission.")
            Container(vectors, "Test Vectors", "Markdown document - repository", "Standard valid and invalid sample messages with the verdict each must get.")
            Container(page, "Invite Page", "Static HTML - UI screen", "The human front door: what AIMF is, how to start, and the agreement registry. Served by Cloudflare Pages; the GitHub Pages copy is a mirror.")
        }

        Boundary(assistant, "Assistant side", "Automation runtime") {
            Container(monitor, "Attempt Monitor", "Scheduled job - worker", "Report-only, as the spec requires: polls the inbound transports, classifies each new message through the gates, dedupes by transport and envelope ID, runs version-verify checks, and reports attempts to Andrew.")
            ContainerDb(state, "Monitor State", "Files, assistant side", "Watermark and seen-message list for dedupe; per-agreement recorded versions.")
        }
    }

    Rel(visitor, page, "Reads the invite", "HTTPS")
    Rel(bot, spec, "Reads the canonical spec", "Raw file")
    Rel(bot, trial, "Runs the trial workflow")
    Rel(bot, transport, "Sends envelope messages")
    Rel(transport, monitor, "New messages are polled")
    Rel(monitor, state, "Dedupes and records versions")
    Rel(monitor, owner, "Reports attempts; surfaces validated messages as data")
    Rel(page, gt, "Translates in the browser")
    Rel(page, wa, "Analytics beacon")
    Rel(spec, page, "The page summarises the spec; the spec governs")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

## Deployment — Host view (v3)

Where each part actually runs: **GitHub** holds the canonical repo
and the mirror page, **Cloudflare Pages** serves the canonical
invite page and counts its visits, the **transports** arrive
through Google and chat services, and **Muse — assistant side**
runs the monitor. People stand outside every host.

```mermaid
C4Deployment
    title AIMF - Deployment View (protocol v1.9)

    Person(owner, "Andrew", "Reviews every attempt; approves agreements.")
    Person(bot, "External AI / bot", "Counterparty under an agreement.")
    Person(visitor, "Human visitor", "Reads the invite page.")

    Deployment_Node(github, "GitHub", "Repository hosting + Pages mirror + Actions") {
        Container(repo, "AIMF Protocol Repo", "Git repository", "Canonical source: SPEC.md (v1.9), trial prompt, test vectors, changelog, and the invite page. Every protocol change lands here first.")
        Container(mirror, "GitHub Pages Mirror", "Static HTML - UI screen", "The invite page on the github.io address, kept as a mirror; its canonical tag points at the subdomain.")
        Container(ci, "CI Workflows", "GitHub Actions - worker", "The thin fleet-CI caller (validation, links, Lighthouse) on every push.")
    }

    Deployment_Node(cloudflare, "Cloudflare Pages", "Canonical hosting + analytics") {
        Container(page, "Invite Page", "Static HTML - UI screen", "The canonical front door at aimf.andrewdhorowitz.com: the pitch, the start-here path, and the agreement registry.")
        Container(wa, "Web Analytics Beacon", "Cloudflare Web Analytics - server", "Page-level counts for the subdomain, from the beacon embedded in the page.")
    }

    Deployment_Node(transports, "Message transports", "Where envelopes arrive") {
        Container_Ext(mail, "Email", "Gmail - cloud", "Envelope as subject + body, to Andrew's mailbox.")
        Container_Ext(drive, "Shared Drive Folder", "Google Drive - cloud", "Envelope as a dropped markdown file.")
        Container_Ext(chat, "Designated Chat", "Chat service - cloud", "Envelope as a chat message in a chat Andrew has designated.")
    }

    Deployment_Node(muse, "Muse - assistant side", "Automation runtime") {
        Container(monitor, "Attempt Monitor", "Scheduled job - worker", "Polls the transports, classifies attempts through the gates, dedupes, version-verifies, and reports to Andrew. Report-only: it never replies or acts.")
        ContainerDb(state, "Monitor State", "Files, assistant side", "Watermark, seen-message list, recorded agreement versions.")
    }

    Deployment_Node(third, "Third-party services", "External widgets") {
        Container_Ext(gt, "GTranslate", "Hosted widget - cloud", "Automatic translation of the invite page into the visitor's language.")
    }

    Rel(visitor, page, "Reads the invite", "HTTPS")
    Rel(bot, repo, "Reads the spec and trial prompt", "Raw files")
    Rel(bot, mail, "Sends an envelope by email")
    Rel(bot, drive, "Drops an envelope file")
    Rel(bot, chat, "Sends an envelope by chat")
    Rel(monitor, mail, "Polls for attempts")
    Rel(monitor, drive, "Polls for attempts")
    Rel(monitor, chat, "Polls for attempts")
    Rel(monitor, state, "Dedupes; records versions")
    Rel(monitor, owner, "Reports attempts and validated messages")
    Rel(repo, page, "Deploys the invite page")
    Rel(repo, mirror, "Deploys the mirror")
    Rel(page, wa, "Analytics beacon")
    Rel(page, gt, "Translation in the browser")
    Rel(ci, repo, "Checks every push")

    UpdateLayoutConfig($c4ShapeInRow="2", $c4BoundaryInRow="1")
```

### Shape and host legend

| Visual | Means | AIMF examples |
|---|---|---|
| Person figure | A human user | Andrew, Human visitor |
| Browser window | A user screen / UI | Invite Page, GitHub Pages Mirror |
| Server rack | A server / server-side function | Web Analytics Beacon |
| Gear | A worker / background or scheduled job | Attempt Monitor, CI Workflows |
| Cylinder | A database / data store | Monitor State |
| Cloud | An external hosted service | Email, Shared Drive Folder, Designated Chat, GTranslate |
| Repository | A source / code store | AIMF Protocol Repo; the Spec, Trial Prompt, and Test Vectors inside it |

Hosts: **GitHub** (repo, mirror, Actions), **Cloudflare Pages**
(canonical page + analytics), **Message transports** (Gmail,
Drive, chat), **Muse — assistant side** (the monitor),
**Third-party services** (GTranslate). The External AI / bot is a
counterparty, drawn as a person-shape actor: it acts for a human
under an agreement.

## The three flows

**1. Reading and onboarding.** A bot reads the canonical spec
from the repo's raw files — never from a summary or a share link —
and runs the trial prompt: the first test is simulated inside its
own chat, and one real send test happens only after its human
explicitly approves it. Onboarding ends in an agreement that
records the level, the message types allowed, and each side's
update-watching method.

**2. A message arrives.** The envelope rides any transport —
email, a Drive file, a designated chat. The Attempt Monitor polls,
and classifies the message through the gates in order: is the
sender allowlisted and bound to the transport-authenticated
identity? Does it validate against the schema? Is its type one of
the documented types, at the agreement's level? Whatever passes
is surfaced to Andrew **as data**; whatever fails is reported as
an attempt. Nothing is acted on, and nothing goes back out,
without Andrew's own approval.

**3. Updates.** A protocol change is real only when it is in the
repo, and it posts only when the spec, trial prompt, changelog,
and invite page (including the agreement registry) are all updated
in the same posting. Counterparties acknowledge an announced
update with a STATUS message naming the new version; the monitor
flags a missing acknowledgement as overdue.

## Containers at a glance

| Container | Shape in diagram | Runs on | Responsibility |
|---|---|---|---|
| Protocol Spec (SPEC.md) | Repository - document | GitHub repo | The format: envelope, gates, types, agreements, update and monitoring rules |
| Trial Prompt | Repository - document | GitHub repo | Turns any AI chat into a trial counterparty, simulate-before-real |
| Test Vectors | Repository - document | GitHub repo | Valid/invalid samples with expected verdicts |
| Invite Page | Browser window - UI screen | Cloudflare Pages | The human front door; agreement registry |
| GitHub Pages Mirror | Browser window - UI screen | GitHub Pages | Mirror of the invite page; canonical points at the subdomain |
| Attempt Monitor | Gear - scheduled worker | Assistant side | Report-only polling, gate classification, dedupe, version-verify |
| Monitor State | Cylinder - data store | Assistant side | Watermark, seen list, recorded versions |
| CI Workflows | Gear - worker | GitHub Actions | Fleet-CI caller: validation, links, Lighthouse |
| Web Analytics Beacon | Server rack - server | Cloudflare | Page-level counts for the subdomain |
| Inbound Transports | Cloud - external service | Gmail / Drive / chat | Carry the same envelope three ways |

## Sources

Built from the AIMF repo (`SPEC.md` v1.9, `README.md`,
`index.html`, `CHANGELOG.md`) and the recorded Oct 29 move: the
Cloudflare Pages project serving aimf.andrewdhorowitz.com as
canonical, the GitHub Pages page kept as mirror, and the Web
Analytics beacon installed the same night. The two-lane hosting
model is unchanged; AIMF's subdomain is a deliberate, reversible
trial exception to it.
