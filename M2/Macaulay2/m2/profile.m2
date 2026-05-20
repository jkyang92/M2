-- Copyright 2024 by Mahrud Sayrafi

-- 'profile' is an interpreter keyword, defined in d/profiler.dd,
-- which logs statistics of executed M2 code in 'ProfileTable'.
-- TODO: log the relationship between function calls and return
-- in an external format like Graphviz, pprof, etc.

needs "methods.m2"

head := () -> ("#run", "cost", "position")
form := (ttime, t, n, pairs, loc) -> (n,
    format(4,2,2,2,"e", 100 * t / ttime), loc)
tail := (ttime, tticks) -> (
    tticks, format(4,4,4,4,"e",ttime) | "s", "elapsed total")

-- SE variants include start/end timestamps for each entry,
-- enabled by the ShowStartEnd option of profileSummary
headSE := () -> ("#run", "cost", "start", "end", "position")
formSE := (ttime, tstart, t, n, pairs, loc) -> (
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

-- =====================================================================
-- flameGraph: render an SVG flame chart from ProfileTable data using
-- Brendan Gregg's FlameGraph tools (https://github.com/brendangregg/FlameGraph).
-- Profile records are emitted as Chrome Trace Event Format JSON, then
-- piped through stackcollapse-chrome-tracing.py and flamegraph.pl
-- --flamechart. The collapser reconstructs parent/child relationships
-- from interval containment, so all events share pid=1, tid=1.
-- Requires flamegraph.pl and stackcollapse-chrome-tracing.py on PATH.
-- =====================================================================

flameGraph'jsonEscape := s -> (
    s = replace("\\\\", "\\\\\\\\", s);
    s = replace("\"", "\\\\\"", s);
    s = replace("\n", "\\\\n",   s);
    s = replace("\r", "\\\\r",   s);
    s = replace("\t", "\\\\t",   s);
    s)

-- emit Chrome Trace JSON for records {loc, start, end} (times in seconds).
-- Times are scaled to nanoseconds to preserve sub-µs resolution.
flameGraph'toJSON := records -> (
    events := apply(records, r -> concatenate(
	    "{\"pid\":1,\"tid\":1,\"ph\":\"X\",\"name\":\"",
	    flameGraph'jsonEscape r#0,
	    "\",\"ts\":",  toString floor(r#1 * 1e9),
	    ",\"dur\":",   toString floor((r#2 - r#1) * 1e9), "}"));
    concatenate("{\"traceEvents\":[\n", demark(",\n", events), "\n]}\n"))

flameGraph = method(Dispatch => Thing, Options => true)
flameGraph Thing := {
    Width      => 1200,
    MinWidth   => 0.5,
    OutputFile => null
    } >> opt -> x ->
    flameGraph(if x === () then "" else first locate x, opt)
flameGraph String := {
    Width      => 1200,
    MinWidth   => 0.5,
    OutputFile => null
    } >> opt -> filename -> (
    -- Filtering before tree-building can flatten the hierarchy if a frame's
    -- true parent lives in another file; matches profileSummary's semantics.
    records := flatten apply(pairs ProfileTable, (k, v) ->
	if k === "total" or not match(filename, toString k) then {}
	else (
	    loc := toString k;
	    apply(v#2, p -> {loc, first p, last p})));
    if #records == 0 then error "flameGraph: no profile data matching filter";
    --
    onPath := name -> run("command -v " | name | " > /dev/null 2>&1") == 0;
    flamegraphPlPath := if fileExists(applicationDirectory() | "local/bin/flamegraph.pl") then (
        applicationDirectory() | "local/bin/flamegraph.pl"
    ) else if onPath "flamegraph.pl" then (
        "flamegraph.pl"
    ) else (
        null
    );
    stackcollapsePyPath := if fileExists(applicationDirectory() | "local/bin/stackcollapse-chrome-tracing.py") then (
        applicationDirectory() | "local/bin/stackcollapse-chrome-tracing.py"
    ) else if onPath "stackcollapse-chrome-tracing.py" then (
        "stackcollapse-chrome-tracing.py"
    ) else (
        null
    );
    if flamegraphPlPath === null or stackcollapsePyPath === null
    then error("flameGraph requires flamegraph.pl and stackcollapse-chrome-tracing.py from "
	| "https://github.com/brendangregg/FlameGraph to be on PATH.\n"
	| "You can install them automatically by running: installFlameGraph()");
    -- stackcollapse-chrome-tracing.py ships with a #!/usr/bin/python shebang that
    -- is missing on macOS and many modern Linux distros; run via python/python3 explicitly.
    pythonCmd := if onPath "python" then "python"
	else if onPath "python3" then "python3"
	else error "flameGraph requires python or python3 on PATH";
    collapseCmd := if stackcollapsePyPath == "stackcollapse-chrome-tracing.py" then (
        pythonCmd | " \"$(command -v stackcollapse-chrome-tracing.py)\""
    ) else (
        pythonCmd | " " | format stackcollapsePyPath
    );
    --
    jsonFile := temporaryFileName() | ".json";
    addEndFunction(() -> if fileExists jsonFile then removeFile jsonFile);
    jsonFile << flameGraph'toJSON records << close;
    --
    svgFile := if opt.OutputFile === null then (
	t := temporaryFileName() | ".svg";
	addEndFunction(() -> if fileExists t then removeFile t);
	t) else toString opt.OutputFile;
    --
    flamegraphPlCmd := if flamegraphPlPath == "flamegraph.pl" then (
        "perl \"$(command -v flamegraph.pl)\""
    ) else (
        "perl " | format flamegraphPlPath
    );
    cmd := concatenate(
	collapseCmd, " ", format jsonFile,
	" | ", flamegraphPlCmd, " --flamechart --countname ns",
	" --title \"M2 Profile Flame Chart\"",
	" --width ",    toString opt.Width,
	" --minwidth ", toString opt.MinWidth,
	" > ", format svgFile);
    r := run cmd;
    if r != 0 then error("flameGraph: external tools failed (exit " | toString r | ")");
    --
    show URL urlEncode(rootURI | realpath svgFile);
    svgFile)
flameGraph = new Command from flameGraph

-- =====================================================================
-- installFlameGraph: download and install Brendan Gregg's FlameGraph
-- scripts to applicationDirectory() | "local/bin/"
-- =====================================================================
installFlameGraph = Command (() -> (
    localDir := applicationDirectory() | "local/";
    binDir := localDir | "bin/";
    makeDirectory(localDir);
    makeDirectory(binDir);
    
    flamegraphPl := binDir | "flamegraph.pl";
    stackcollapsePy := binDir | "stackcollapse-chrome-tracing.py";
    
    urls := {
        ("flamegraph.pl", "https://raw.githubusercontent.com/brendangregg/FlameGraph/master/flamegraph.pl", flamegraphPl),
        ("stackcollapse-chrome-tracing.py", "https://raw.githubusercontent.com/brendangregg/FlameGraph/master/stackcollapse-chrome-tracing.py", stackcollapsePy)
    };
    
    onPath := name -> run("command -v " | name | " > /dev/null 2>&1") == 0;
    
    scan(urls, (name, url, dest) -> (
        printerr("Downloading " | name | "...");
        success := false;
        if onPath "curl" then (
            success = run("curl -s -L -o " | format dest | " " | format url) == 0;
        ) else if onPath "wget" then (
            success = run("wget -q -O " | format dest | " " | format url) == 0;
        );
        if not success then (
            -- fallback to Macaulay2's own http implementation
            try (
                response := getWWW url;
                body := (splitWWW response)#1;
                dest << body << close;
                success = true;
            ) catch (
                -- ignore
            );
        );
        if success then (
            run("chmod +x " | format dest);
            printerr("Successfully installed " | name | " to " | dest);
        ) else (
            error("Failed to download " | name | ". Please download it manually from " | url | " and place it in your PATH or " | dest);
        );
    ));
))

-- prints a list of lines which have been seen by the profiler so far
-- TODO: also highlight missing lines or sections within a line
-- TODO: compute the percentage of covered code
coverageSummary = method(Dispatch => Thing)
coverageSummary Thing := x -> coverageSummary if x === () then "" else first locate x
coverageSummary String := filename -> (
    body := sort select(toString \ keys ProfileTable, match_filename);
    stack join({"covered lines:"}, body))
coverageSummary = new Command from coverageSummary
