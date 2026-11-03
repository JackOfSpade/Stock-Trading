# What routines actually read at startup

Measured 2026-11-03 from `RemoteTrigger get_run_log`, using the size of each tool result. Five runs only, so treat these as a sample, not a fleet average. Sizes are approximate, and tokens are bytes divided by 4.

| Run | Date | Kind | Own instructions read | Shared preamble read | Total | About tokens |
|---|---|---|---|---|---|---|
| M1R | 11-01 | quiet | 15 KB | 3 KB | 23 KB | 6k |
| SL3 | 10-30 | quiet | 45 KB | 0 KB, copied the previous run's rows instead | 70 KB | 17k |
| SL5 | 11-03 | quiet | 60 KB | 40 KB | 105 KB | 26k |
| AR_att | 11-02 | quiet | 55 KB | 41 KB | 103 KB | 26k |
| D1 | 11-02 | full | 117 KB | 56 KB | 185 KB | 46k |

The shared preamble is 198,904 bytes, about 50k tokens. No sampled run read all of it. The earlier estimate of 29M tokens per 60 days assumed a full read and is about 5 to 7 times too high.

## Findings

- Routines do not use the generated slices. All five start with `grep` and `sed` on `Claude_Task_Plan.md`.
- Each read counts more than once: its text stays in context for every later turn, at the cached rate. SL5 took 26 turns and M1R 16.
- M1R's quiet path works. Its gate sits near the top of its section, and it read about a quarter of what SL5 and AR_att read.
- Partial reading already has a cost. SL3 skipped the run-logging rules, copied the previous run, stamped the wrong session id and then hand-corrected `ops.run_log` with an UPDATE. Several runs also guessed column names and hit query errors.
- SL3 spent about 83k subagent tokens on a citation re-audit during a run with no incubating strategies, about 5 times what its main read cost.

## Rough size of each lever, per 60 days

These extrapolate from single runs, and subagent totals include repeated context, so the first two rows are not directly comparable with the last two.

| Lever | Basis | Tokens |
|---|---|---|
| J paper book | 554k subagent tokens x 41 runs | 23M |
| D1 screen record | 417k subagent tokens x 41 runs | 17M |
| Quiet-path gates on AR_att, AR_orc, SL2, SL3, SL5 | About 20k first-read tokens x 170 quiet fires | 3-4M, more with per-turn repeats |
| SL3 re-audit on empty runs | 83k x 40 runs | 3M, if every run does it |
