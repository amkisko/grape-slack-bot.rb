# RFC-0001 RFC process

- Type: Procedural
- Status: Proposed
- Created: 2026-11-18
- Author: Codex

## Summary

Maintain numbered proposals for public contract changes.

## Motivation

Maintainers and consumers need a stable reference for API and protocol decisions
across design, implementation, and release.

## Guide-level explanation

Reserve the next free number with an `ids/NNNN` file containing the proposal's
slug. Copy the template to `NNNN-slug.md`, update the index, and open a proposal
for review. Cite `RFC-NNNN` in implementation pull requests.

## Reference-level explanation

Number proposals sequentially across types. Keep retired identifiers reserved.
Use Standards Track for public contracts, Procedural for project process,
Informational for analysis, and Historical for pre-process contracts.

Use Draft during authoring, Experimental for published designs under trial, and
Proposed for changes open to review. Allow at least two weeks of review for a
Proposed change before marking it Stable. Use Final for deployed contracts
that require a new RFC to change. Use Deferred, Rejected, Superseded, or
Obsolete as applicable.

## Unresolved questions

Maintainers can introduce numbering bands if the proposal queue grows.
