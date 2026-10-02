# 0006: Every gate must be proven to fail

## Context

The point of the CI gate is to make automated Hugo upgrades safe. A check that
passes without actually checking anything is worse than no check: it produces
confidence without evidence.

This is not hypothetical. During this build, four checks were found to be
passing while verifying nothing:

- The lint self test read stylelint's stdout, but stylelint writes its report to
  stderr when a run has errors, so the test that asks "did every rule fire?"
  was inspecting an empty string.
- The protected path check used a shell glob that expanded against the current
  directory, so the foundation directory rule matched nothing inside a
  consuming site, which is the only place it matters.
- Lighthouse was auditing six pages chosen by its own discovery, and the page
  with images was not among them, so nothing gated image weight or layout
  shift.
- Structured data was emitted as a JSON string rather than an object, because
  template escaping quoted it inside the script element. It looked correct in
  the page source and would have been ignored by every crawler.

## Decision

Every gate ships with a demonstration that it fails:

- axe runs against a deliberately broken fixture that must fail.
- The CSS lint runs against a fixture where every rule must fire.
- Checks are verified by removing what they protect and watching them go red.
- A flaky check is treated as a broken check, not a retry: the dark mode
  contrast failure that appeared once in CI was a race, and the fix was to wait
  for stylesheets rather than to re-run.

## Consequences

- Each check costs a fixture and a test of its own.
- A failing check is trusted, because its failure mode has been seen.
- New checks are expected to arrive with their negative case, which is why
  issue text asks for one.
