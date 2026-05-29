using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

try
{
    var options = HelperOptions.Parse(args);
    if (options.ShowHelp)
    {
        Console.WriteLine(HelperOptions.HelpText);
        return 0;
    }

    if (options.SelfTest)
    {
        return SelfTest.Run();
    }

    var cts = new CancellationTokenSource();
    Console.CancelKeyPress += (_, eventArgs) =>
    {
        eventArgs.Cancel = true;
        cts.Cancel();
    };

    var events = new EventStore();
    var tasks = new List<Task>
    {
        TcpEventServer.RunAsync(options, events, cts.Cancel, cts.Token)
    };

    if (options.KeyboardEnabled)
    {
        tasks.Add(KeyboardFrequencyMonitor.RunAsync(events, cts.Token));
    }

    if (!string.IsNullOrWhiteSpace(options.GitRepo))
    {
        tasks.Add(GitPushMonitor.RunAsync(options.GitRepo, events, cts.Token));
    }

if (!string.IsNullOrWhiteSpace(options.TokenLog))
{
    tasks.Add(TokenLogMonitor.RunAsync(options.TokenLog, events, cts.Token));
}

if (options.DemoEvents)
{
    tasks.Add(DemoEventEmitter.RunAsync(events, cts.Token));
}

Console.WriteLine($"DeskMochi helper listening on http://127.0.0.1:{options.Port}/");
    Console.WriteLine("Press Ctrl+C to stop.");
    await Task.WhenAll(tasks).ConfigureAwait(false);
    return 0;
}
catch (OperationCanceledException)
{
    return 0;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"DeskMochi helper stopped after an error: {ex}");
    return 1;
}

internal sealed record HelperEvent(long Id, string Type, long UnixMs, Dictionary<string, object> Payload);

internal sealed class EventStore
{
    private readonly ConcurrentQueue<HelperEvent> _events = new();
    private long _nextId;

    public HelperEvent Emit(string type, Dictionary<string, object> payload)
    {
        var item = new HelperEvent(
            Interlocked.Increment(ref _nextId),
            type,
            DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
            payload);
        _events.Enqueue(item);

        while (_events.Count > 256 && _events.TryDequeue(out _))
        {
        }

        return item;
    }

    public HelperEvent[] Since(long lastId)
    {
        return _events.Where(item => item.Id > lastId).OrderBy(item => item.Id).ToArray();
    }
}

internal sealed record HelperOptions(
    int Port,
    bool KeyboardEnabled,
    string GitRepo,
    string TokenLog,
    bool DemoEvents,
    bool SelfTest,
    bool ShowHelp)
{
    public const string HelpText = """
DeskMochi.Helper

Options:
  --config <path>       Load JSON config, then apply command-line overrides.
  --port <number>       Local HTTP port. Default: 8765.
  --keyboard            Enable privacy-preserving keyboard frequency sampling.
  --git-repo <path>     Monitor a local Git repo for push-like remote ref updates.
  --token-log <path>    Monitor an AI agent log file for token count lines.
  --demo-events         Emit a few synthetic events for visual smoke checks.
  --self-test           Run deterministic parser checks and exit.
  --help                Show this help.
""";

    public static HelperOptions Parse(string[] args)
    {
        var configPath = "";
        var port = 8765;
        var keyboard = false;
        var gitRepo = "";
        var tokenLog = "";
        var demoEvents = false;
        var selfTest = false;
        var showHelp = false;

        for (var index = 0; index < args.Length; index++)
        {
            var arg = args[index];
            if (arg == "--config" && index + 1 < args.Length)
            {
                configPath = args[++index];
            }
        }

        if (!string.IsNullOrWhiteSpace(configPath))
        {
            var config = HelperConfig.Load(configPath);
            port = config.Port ?? port;
            keyboard = config.KeyboardEnabled ?? keyboard;
            gitRepo = config.GitRepo ?? gitRepo;
            tokenLog = config.TokenLog ?? tokenLog;
            demoEvents = config.DemoEvents ?? demoEvents;
        }

        for (var index = 0; index < args.Length; index++)
        {
            var arg = args[index];
            if (arg == "--config" && index + 1 < args.Length)
            {
                index++;
            }
            else if (arg == "--port" && index + 1 < args.Length)
            {
                port = int.Parse(args[++index]);
            }
            else if (arg == "--keyboard")
            {
                keyboard = true;
            }
            else if (arg == "--git-repo" && index + 1 < args.Length)
            {
                gitRepo = args[++index];
            }
            else if (arg == "--token-log" && index + 1 < args.Length)
            {
                tokenLog = args[++index];
            }
            else if (arg == "--demo-events")
            {
                demoEvents = true;
            }
            else if (arg == "--self-test")
            {
                selfTest = true;
            }
            else if (arg == "--help" || arg == "-h")
            {
                showHelp = true;
            }
        }

        return new HelperOptions(port, keyboard, gitRepo, tokenLog, demoEvents, selfTest, showHelp);
    }
}

internal sealed record HelperConfig(int? Port, bool? KeyboardEnabled, string? GitRepo, string? TokenLog, bool? DemoEvents)
{
    public static HelperConfig Load(string path)
    {
        var json = File.ReadAllText(path);
        return JsonSerializer.Deserialize<HelperConfig>(json, JsonOptions.Default) ?? new HelperConfig(null, null, null, null, null);
    }
}

internal static class TcpEventServer
{
    public static async Task RunAsync(HelperOptions options, EventStore events, Action requestShutdown, CancellationToken token)
    {
        var listener = new TcpListener(IPAddress.Loopback, options.Port);
        listener.Start();

        try
        {
            while (!token.IsCancellationRequested)
            {
                TcpClient client;
                try
                {
                    client = await listener.AcceptTcpClientAsync(token).ConfigureAwait(false);
                }
                catch (OperationCanceledException)
                {
                    break;
                }

                _ = Task.Run(() => HandleAsync(client, events, requestShutdown), CancellationToken.None);
            }
        }
        finally
        {
            listener.Stop();
        }
    }

    private static async Task HandleAsync(TcpClient client, EventStore events, Action requestShutdown)
    {
        using var ownedClient = client;
        await using var stream = ownedClient.GetStream();

        try
        {
            using var reader = new StreamReader(stream, Encoding.ASCII, leaveOpen: true);
            var requestLine = await reader.ReadLineAsync().ConfigureAwait(false) ?? "";
            while (!string.IsNullOrEmpty(await reader.ReadLineAsync().ConfigureAwait(false)))
            {
            }

            var parts = requestLine.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            var target = parts.Length >= 2 ? parts[1] : "/";
            var path = target.Split('?', 2)[0];

            if (path == "/health")
            {
                await WriteJsonAsync(stream, 200, new { ok = true }).ConfigureAwait(false);
                return;
            }

            if (path == "/shutdown")
            {
                await WriteJsonAsync(stream, 200, new { ok = true, shutting_down = true }).ConfigureAwait(false);
                requestShutdown();
                return;
            }

            if (path == "/events")
            {
                var lastIdValue = QueryValue(target, "last_id");
                _ = long.TryParse(lastIdValue, out var lastId);
                await WriteJsonAsync(stream, 200, new { events = events.Since(lastId) }).ConfigureAwait(false);
                return;
            }

            await WriteJsonAsync(stream, 404, new { error = "not_found" }).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            await WriteJsonAsync(stream, 500, new { error = ex.Message }).ConfigureAwait(false);
        }
    }

    private static string QueryValue(string target, string name)
    {
        var queryStart = target.IndexOf('?');
        if (queryStart < 0 || queryStart == target.Length - 1)
        {
            return "";
        }

        var query = target[(queryStart + 1)..];
        foreach (var pair in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var parts = pair.Split('=', 2);
            if (parts.Length == 2 && Uri.UnescapeDataString(parts[0]) == name)
            {
                return Uri.UnescapeDataString(parts[1]);
            }
        }

        return "";
    }

    private static async Task WriteJsonAsync(Stream stream, int status, object value)
    {
        var bytes = JsonSerializer.SerializeToUtf8Bytes(value, JsonOptions.Default);
        var reason = status == 200 ? "OK" : status == 404 ? "Not Found" : "Internal Server Error";
        var header = Encoding.ASCII.GetBytes(
            $"HTTP/1.1 {status} {reason}\r\n" +
            "Content-Type: application/json\r\n" +
            $"Content-Length: {bytes.Length}\r\n" +
            "Connection: close\r\n" +
            "\r\n");
        await stream.WriteAsync(header).ConfigureAwait(false);
        await stream.WriteAsync(bytes).ConfigureAwait(false);
    }
}

internal static class JsonOptions
{
    public static readonly JsonSerializerOptions Default = new(JsonSerializerDefaults.Web)
    {
        WriteIndented = false
    };
}

internal static partial class KeyboardFrequencyMonitor
{
    private const int SampleMs = 50;
    private const int WindowMs = 5000;

    public static async Task RunAsync(EventStore events, CancellationToken token)
    {
        if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            events.Emit("helper_warning", new Dictionary<string, object>
            {
                ["source"] = "keyboard",
                ["message"] = "Keyboard monitor is Windows-only."
            });
            return;
        }

        var previous = new bool[256];
        var timestamps = new Queue<long>();

        while (!token.IsCancellationRequested)
        {
            var now = Environment.TickCount64;
            for (var key = 8; key < 256; key++)
            {
                var down = (GetAsyncKeyState(key) & 0x8000) != 0;
                if (down && !previous[key])
                {
                    timestamps.Enqueue(now);
                }

                previous[key] = down;
            }

            while (timestamps.Count > 0 && now - timestamps.Peek() > WindowMs)
            {
                timestamps.Dequeue();
            }

            var perMinute = timestamps.Count * (60000.0 / WindowMs);
            if (perMinute >= 60.0)
            {
                events.Emit("keyboard_activity", new Dictionary<string, object>
                {
                    ["keys_per_minute"] = Math.Round(perMinute, 1),
                    ["sample_window_ms"] = WindowMs
                });
            }

            await Task.Delay(SampleMs, token).ConfigureAwait(false);
        }
    }

    [LibraryImport("user32.dll")]
    private static partial short GetAsyncKeyState(int virtualKey);
}

internal static class GitPushMonitor
{
    public static async Task RunAsync(string repoPath, EventStore events, CancellationToken token)
    {
        var gitDir = ResolveGitDir(repoPath);
        if (gitDir is null)
        {
            events.Emit("helper_warning", new Dictionary<string, object>
            {
                ["source"] = "git",
                ["message"] = $"No .git directory found for {repoPath}"
            });
            return;
        }

        var snapshot = SnapshotRemoteLogs(gitDir);
        while (!token.IsCancellationRequested)
        {
            await Task.Delay(2000, token).ConfigureAwait(false);
            var next = SnapshotRemoteLogs(gitDir);
            foreach (var item in next)
            {
                if (!snapshot.TryGetValue(item.Key, out var oldValue) || oldValue.LastWriteUtc != item.Value.LastWriteUtc || oldValue.Length != item.Value.Length)
                {
                    events.Emit("git_push", new Dictionary<string, object>
                    {
                        ["repo"] = Path.GetFullPath(repoPath),
                        ["ref"] = item.Key.Replace('\\', '/'),
                        ["note"] = "remote ref log changed"
                    });
                }
            }

            snapshot = next;
        }
    }

    public static string? ResolveGitDir(string repoPath)
    {
        var direct = Path.Combine(repoPath, ".git");
        if (Directory.Exists(direct))
        {
            return direct;
        }

        if (!File.Exists(direct))
        {
            return null;
        }

        var content = File.ReadAllText(direct).Trim();
        const string prefix = "gitdir:";
        if (!content.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var relative = content[prefix.Length..].Trim();
        return Path.GetFullPath(relative, repoPath);
    }

    public static Dictionary<string, FileSnapshot> SnapshotRemoteLogs(string gitDir)
    {
        var root = Path.Combine(gitDir, "logs", "refs", "remotes");
        if (!Directory.Exists(root))
        {
            return new Dictionary<string, FileSnapshot>();
        }

        return Directory.EnumerateFiles(root, "*", SearchOption.AllDirectories)
            .ToDictionary(
                path => Path.GetRelativePath(root, path),
                path =>
                {
                    var info = new FileInfo(path);
                    return new FileSnapshot(info.Length, info.LastWriteTimeUtc);
                });
    }
}

internal readonly record struct FileSnapshot(long Length, DateTime LastWriteUtc);

internal static partial class TokenLogMonitor
{
    public static async Task RunAsync(string logPath, EventStore events, CancellationToken token)
    {
        long offset = 0;
        if (File.Exists(logPath))
        {
            offset = new FileInfo(logPath).Length;
        }

        while (!token.IsCancellationRequested)
        {
            await Task.Delay(1500, token).ConfigureAwait(false);
            if (!File.Exists(logPath))
            {
                continue;
            }

            using var stream = new FileStream(logPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
            if (stream.Length < offset)
            {
                offset = 0;
            }

            stream.Seek(offset, SeekOrigin.Begin);
            using var reader = new StreamReader(stream, Encoding.UTF8, true, leaveOpen: true);
            while (true)
            {
                var line = await reader.ReadLineAsync(token).ConfigureAwait(false);
                if (line is null)
                {
                    break;
                }

                var count = ParseTokenCount(line ?? "");
                if (count > 0)
                {
                    events.Emit("token_usage", new Dictionary<string, object>
                    {
                        ["tokens"] = count,
                        ["source"] = logPath
                    });
                }
            }

            offset = stream.Position;
        }
    }

    public static int ParseTokenCount(string line)
    {
        var match = TokenPattern().Match(line);
        if (!match.Success)
        {
            return 0;
        }

        return int.TryParse(match.Groups["count"].Value, out var count) ? count : 0;
    }

    [GeneratedRegex(@"(?i)\b(tokens?|token_count|total_tokens)\b[^0-9]{0,16}(?<count>[0-9]{1,9})")]
    private static partial Regex TokenPattern();
}

internal static class DemoEventEmitter
{
    public static async Task RunAsync(EventStore events, CancellationToken token)
    {
        var sequence = new (int DelayMs, string Type, Dictionary<string, object> Payload)[]
        {
            (4000, "keyboard_activity", new Dictionary<string, object>
            {
                ["keys_per_minute"] = 168.0,
                ["sample_window_ms"] = 5000,
                ["source"] = "demo"
            }),
            (4000, "token_usage", new Dictionary<string, object>
            {
                ["tokens"] = 12345,
                ["source"] = "demo"
            }),
            (4000, "git_push", new Dictionary<string, object>
            {
                ["repo"] = "demo",
                ["ref"] = "origin/main",
                ["note"] = "demo event"
            }),
        };

        foreach (var item in sequence)
        {
            await Task.Delay(item.DelayMs, token).ConfigureAwait(false);
            events.Emit(item.Type, item.Payload);
        }
    }
}

internal static class SelfTest
{
    public static int Run()
    {
        if (TokenLogMonitor.ParseTokenCount("total_tokens: 12345") != 12345)
        {
            Console.Error.WriteLine("Token parser failed total_tokens case.");
            return 1;
        }

        if (TokenLogMonitor.ParseTokenCount("tokens used = 89") != 89)
        {
            Console.Error.WriteLine("Token parser failed tokens used case.");
            return 1;
        }

        if (TokenLogMonitor.ParseTokenCount("nothing useful here") != 0)
        {
            Console.Error.WriteLine("Token parser false positive.");
            return 1;
        }

        var configPath = Path.Combine(Path.GetTempPath(), $"deskmochi-helper-{Guid.NewGuid():N}.json");
        File.WriteAllText(configPath, """
{
  "port": 9001,
  "keyboardEnabled": true,
  "gitRepo": "D:\\Repo",
  "tokenLog": "D:\\agent.log"
}
""");
        try
        {
            var options = HelperOptions.Parse(["--config", configPath, "--port", "9002", "--demo-events"]);
            if (options.Port != 9002 || !options.KeyboardEnabled || options.GitRepo != "D:\\Repo" || options.TokenLog != "D:\\agent.log" || !options.DemoEvents)
            {
                Console.Error.WriteLine("Config parser failed.");
                return 1;
            }
        }
        finally
        {
            File.Delete(configPath);
        }

        using var temp = new TempGitLogFixture();
        var first = GitPushMonitor.SnapshotRemoteLogs(temp.GitDir);
        File.AppendAllText(temp.RemoteLog, "push update\n");
        var second = GitPushMonitor.SnapshotRemoteLogs(temp.GitDir);
        var key = Path.Combine("origin", "main");
        if (!first.TryGetValue(key, out var before) || !second.TryGetValue(key, out var after) || after.Length <= before.Length)
        {
            Console.Error.WriteLine("Git remote log snapshot failed.");
            return 1;
        }

        Console.WriteLine("DeskMochi.Helper self-test OK");
        return 0;
    }

    private sealed class TempGitLogFixture : IDisposable
    {
        private readonly string _root = Path.Combine(Path.GetTempPath(), "DeskMochi.Helper.Tests", Guid.NewGuid().ToString("N"));

        public TempGitLogFixture()
        {
            GitDir = Path.Combine(_root, ".git");
            RemoteLog = Path.Combine(GitDir, "logs", "refs", "remotes", "origin", "main");
            Directory.CreateDirectory(Path.GetDirectoryName(RemoteLog)!);
            File.WriteAllText(RemoteLog, "initial\n");
        }

        public string GitDir { get; }
        public string RemoteLog { get; }

        public void Dispose()
        {
            try
            {
                Directory.Delete(_root, recursive: true);
            }
            catch
            {
            }
        }
    }
}
