-- Copyright 2024 by Mahrud Sayrafi

-- 'profile' is an interpreter keyword, defined in d/profiler.dd,
-- which logs statistics of executed M2 code in 'ProfileTable'.
-- TODO: log the relationship between function calls and return
-- in an external format like Graphviz, pprof, etc.

needs "methods.m2"

head := () -> ("#run", "cost", "code", "position")
form := (ttime, t, n, pairs, key) -> splice(n,
    format(4,2,2,2,"e", 100 * t / ttime), key#0)
tail := (ttime, tticks) -> (
    tticks, format(4,4,4,4,"e",ttime) | "s", "elapsed total")

-- SE variants include start/end timestamps for each entry,
-- enabled by the ShowStartEnd option of profileSummary
headSE := () -> ("#run", "cost", "start", "end", "position")
formSE := (ttime, tstart, t, n, pairs, loc) -> (
    pairs = take(pairs, n);
    fmtTime := s -> format(4,3,3,3,"e", s - tstart) | "s";
    starts := apply(pairs, first);
    ends   := apply(pairs, last);
    (n,
	format(4,2,2,2,"e", 100 * t / ttime),
	if n > 1 then stack apply(starts, fmtTime) else fmtTime min starts,
	if n > 1 then stack apply(ends,   fmtTime) else fmtTime max ends,
	loc))
tailSE := (ttime, tticks, tstart, tend) -> (
    tticks,
    format(4,4,4,4,"e",ttime) | "s",
    "0s",
    format(4,3,3,3,"e", tend - tstart) | "s",
    "elapsed total")

-- prints the statistics logged by the profiler in a readable table
profileSummary = method(Dispatch => Thing, Options => true)
profileSummary Thing := {MaxEntries => 20, ShowStartEnd => false} >> opt -> x ->
    profileSummary(if x === () then "" else first locate x, opt)
profileSummary String := {MaxEntries => 20, ShowStartEnd => false} >> opt -> filename -> (
    showSE := opt.ShowStartEnd;
    dataset := select(pairs ProfileTable,
	(k, v) -> match_filename toString k);
    if #dataset == 0 then return TABLE {
	if showSE then headSE() else head(),
	if showSE then tailSE(0,0,0,0) else tail(0,0)};
    (ttime, tticks, totPairs) := ProfileTable#"total";
    totPairs = take(totPairs, tticks);
    tstart := min apply(totPairs, first);
    tend   := max apply(totPairs, last);
    data := sort pairs hashTable(join, apply(dataset,
	    (k, v) -> if k =!= "total" then (v, {k})));
    rows := min(opt.MaxEntries, #data);
    high := reverse take(data, {#data - rows - 1, #data - 1});
    body := if showSE
	then apply(rows, i -> formSE_(ttime, tstart) splice high#i)
	else apply(rows, i -> form_ttime splice high#i);
    tailRow := if showSE then tailSE(ttime, tticks, tstart, tend)
	else tail(ttime, tticks);
    TABLE join({if showSE then headSE() else head()}, body, {tailRow}))
profileSummary = new Command from profileSummary

resetProfileTable = new Command from resetProfileTable

-- flameGraph and installFlameGraph live in flameGraph.m2.

-- prints a list of lines which have been seen by the profiler so far
-- TODO: also highlight missing lines or sections within a line
-- TODO: compute the percentage of covered code
coverageSummary = method(Dispatch => Thing)
coverageSummary Thing := x -> coverageSummary if x === () then "" else first locate x
coverageSummary String := filename -> (
    body := sort select(toString \ keys ProfileTable, match_filename);
    stack join({"covered lines:"}, body))
coverageSummary = new Command from coverageSummary
