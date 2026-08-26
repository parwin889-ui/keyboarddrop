using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace KeyboardDrop;

public class Config
{
    public Dictionary<string, object> RawMappings { get; set; } = new();

    public static Config? Load(string path)
    {
        if (!File.Exists(path))
            return null;

        var json = File.ReadAllText(path);
        var doc = JsonDocument.Parse(json);

        var result = new Config();

        if (doc.RootElement.TryGetProperty("mappings", out var mappings))
        {
            foreach (var prop in mappings.EnumerateObject())
            {
                result.RawMappings[prop.Name] = ParseValue(prop.Value);
            }
        }
        else
        {
            foreach (var prop in doc.RootElement.EnumerateObject())
            {
                result.RawMappings[prop.Name] = ParseValue(prop.Value);
            }
        }

        return result;
    }

    private static object ParseValue(JsonElement el)
    {
        if (el.ValueKind == JsonValueKind.String)
            return el.GetString() ?? "";
        return el;
    }

    public static void CreateDefault(string path)
    {
        var dir = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
            Directory.CreateDirectory(dir);

        var defaultJson = @"{
  ""mappings"": {
    ""caps_lock"": ""escape"",
    ""right_win"": ""left_control"",
    ""f5"": { ""type"": ""command"", ""target"": ""notepad"" }
  }
}";
        File.WriteAllText(path, defaultJson);
    }

    public Dictionary<int, KeyAction> ToKeyActions()
    {
        var result = new Dictionary<int, KeyAction>();
        foreach (var (from, raw) in RawMappings)
        {
            var fromCode = KeyMap.CodeFor(from);
            if (fromCode == null)
            {
                System.Console.WriteLine($"  [warning] unknown source key: {from}");
                continue;
            }
            var action = KeyAction.FromConfig(raw);
            if (action != null)
                result[fromCode.Value] = action;
        }
        return result;
    }

    public List<string> Describe()
    {
        var list = new List<string>();
        foreach (var (from, raw) in RawMappings)
        {
            var action = KeyAction.FromConfig(raw);
            list.Add(action != null ? $"{from} {action.Description}" : $"{from} -> (invalid)");
        }
        list.Sort();
        return list;
    }
}
