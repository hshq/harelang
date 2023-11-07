# RFC process

Large and important changes to the Hare programming language are implemented by
a formal process of consensus with a "request for comments" (RFC).

## When to prepare an RFC?

You may prepare an RFC for any change that you want to have a structured
discussion about, large or small. The author of a proposed change may opt-in to
the RFC process if they would find it useful for their work, or a maintainer or
reviewer may invoke the RFC process for a given change at their discretion.

As a rule of thumb, a change is more likely to require an RFC if any of the
following conditions are met:

- A change is controversial and requires discussion to secure consensus
- A standard library change breaks a widely-used API
- A language change requires most Hare users to rewrite their code
- A large number of subsystems are implicated

## 0. Prior to submitting an RFC

Ideas can form anywhere, but once you want to turn an idea into action it is
important to discuss it in the official community spaces so that you can keep
those affected in the loop and prepare people to participate in the consensus
process. You can discuss ideas and early proposals, workshop RFC text, and so
on, in the Hare IRC channels and mailing lists.

Do some research to see which community members should participate in the
discussion, including at a minimum the maintainers of relevant subsystems and a
global maintainer. Seek out their feedback and guidance on your propsal.

## 1. Submitting an RFC

RFCs are formally submitted to the [hare-rfc] mailing list. The subject line
should be "[RFC v1] Subject...", where v1 increments for each revision of the
proposal. Work-in-progress proposals may be submitted to this list with the
"[DRAFT RFC]" subject prefix.

The body of the RFC is free-form text, which should be formatted in accordance
with typical [mailing list etiquette][0], and should include at a minimum the
details of the proposed change, the rationale for the change, and the predicted
impact of the change to end-users. Illustrative code samples and other
supporting materials are encouraged to be included. See doc/rfc-template.txt for
a sample RFC to get started.

[hare-rfc]: https://lists.sr.ht/~sircmpwn/hare-rfc
[0]: https://man.sr.ht/lists.sr.ht/etiquette.md

You can start implementing the change proposed by the RFC for research or
illustrative purposes, but keep in mind that following the discussion of the RFC
much of this code might have to be rewritten.

## 2. Discussion

The proposal is discussed following its submission, and will likely be refined.
Participants will narrow down the details, determine if the implications are
completely enumerated, and make plans for the implementation. This process will
generally result in the RFC draft being adjusted to incorporate feedback and
resubmitted with a new version number.

## 3. Approval

A RFC does not require explicit approval to proceed to the implementation,
though patch authors would be wise to read the room to determine if the
potential code reviewers are satisfied with the status of the proposal, lest you
write code based on it which will ultimately be rejected for foreseeable
reasons.

## 4. Implementation

Once the discussion participants are satisfied with the proposed RFC, the
proposal authors (and/or anyone they convinced to help out during the
discussion) should move forward with implementing the proposal and sending out
the relevant patches.

Once the implementation is complete, the authors should follow-up on the
original proposal thread on the hare-rfc mailing list with details about the
implementation (such as links to the relevant patches) to close the proposal and
record its implementation for posterity.

Proposal authors are also encouraged during the implementation phase to continue
commenting on the RFC thread to record new insights, document deviations from
the proposal that occured in practice, or to go back to the drawing board and
prepare a new revision with the lessons learned from the code.

## FAQ

### Who can submit an RFC?

Anyone.
