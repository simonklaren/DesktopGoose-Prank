using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Text;

namespace GooseDesktop
{
	public static class GooseConfig
	{
		private static readonly string filePath = Program.GetPathToFileInAssembly("config.ini");
		public const int GOOSE_CONFIG_VERSION = 1;
		public static ConfigSettings settings;

		public static void LoadConfig()
		{
			settings = ConfigSettings.ReadFileIntoConfig(filePath);
		}

		public class ConfigSettings
		{
			public int Version_DoNotEdit = GOOSE_CONFIG_VERSION;
			public bool Task_CanAttackMouse = true;
			public bool AttackRandomly = true;
			public float MinWanderingTimeSeconds = 8f;
			public float MaxWanderingTimeSeconds = 15f;
			public float FirstWanderTimeSeconds = 4f;
			public bool RandomizeWindowDropPosition = true;
			public int WindowDropGridColumns = 3;
			public int WindowDropGridRows = 3;
			public int WindowDropEdgeMargin = 50;
			public bool AvoidRecentDropZones = true;

			public static ConfigSettings ReadFileIntoConfig(string configGivenPath)
			{
				ConfigSettings result = new ConfigSettings();
				if (!File.Exists(configGivenPath))
				{
					WriteConfigToFile(configGivenPath, result);
					return result;
				}

				try
				{
					Dictionary<string, string> values = ReadValues(configGivenPath);
					int version;
					string versionText;
					if (values.TryGetValue("Version_DoNotEdit", out versionText)
						&& (!int.TryParse(versionText, out version) || version != GOOSE_CONFIG_VERSION))
					{
						return result;
					}

					foreach (KeyValuePair<string, string> pair in values)
					{
						FieldInfo field = typeof(ConfigSettings).GetField(pair.Key);
						if (field == null) continue;

						object parsedValue;
						if (TryConvert(pair.Value, field.FieldType, out parsedValue))
						{
							field.SetValue(result, parsedValue);
						}
					}
				}
				catch
				{
					// Preserve a corrupt file and use safe defaults for this run.
					return new ConfigSettings();
				}

				result.Sanitize();
				return result;
			}

			private static Dictionary<string, string> ReadValues(string path)
			{
				Dictionary<string, string> values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
				foreach (string rawLine in File.ReadAllLines(path))
				{
					string line = rawLine.Trim();
					if (line.Length == 0 || line.StartsWith("#") || line.StartsWith(";")) continue;

					int separator = line.IndexOf('=');
					if (separator <= 0) continue;
					values[line.Substring(0, separator).Trim()] = line.Substring(separator + 1).Trim();
				}
				return values;
			}

			private static bool TryConvert(string value, Type targetType, out object converted)
			{
				converted = null;
				if (targetType == typeof(bool))
				{
					bool parsed;
					if (!bool.TryParse(value, out parsed)) return false;
					converted = parsed;
					return true;
				}
				if (targetType == typeof(int))
				{
					int parsed;
					if (!int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out parsed)) return false;
					converted = parsed;
					return true;
				}
				if (targetType == typeof(float))
				{
					float parsed;
					if (!float.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out parsed)) return false;
					converted = parsed;
					return true;
				}
				return false;
			}

			private void Sanitize()
			{
				FirstWanderTimeSeconds = Clamp(FirstWanderTimeSeconds, 0f, 3600f);
				MinWanderingTimeSeconds = Clamp(MinWanderingTimeSeconds, 1f, 3600f);
				MaxWanderingTimeSeconds = Clamp(MaxWanderingTimeSeconds, MinWanderingTimeSeconds, 3600f);
				WindowDropGridColumns = Clamp(WindowDropGridColumns, 1, 10);
				WindowDropGridRows = Clamp(WindowDropGridRows, 1, 10);
				WindowDropEdgeMargin = Clamp(WindowDropEdgeMargin, 0, 500);
			}

			private static float Clamp(float value, float minimum, float maximum)
			{
				return Math.Max(minimum, Math.Min(maximum, value));
			}

			private static int Clamp(int value, int minimum, int maximum)
			{
				return Math.Max(minimum, Math.Min(maximum, value));
			}

			public static void WriteConfigToFile(string path, ConfigSettings settingsToWrite)
			{
				using (StreamWriter writer = File.CreateText(path))
				{
					writer.Write(GenerateTextFromSettings(settingsToWrite));
				}
			}

			public static string GenerateTextFromSettings(ConfigSettings settingsToWrite)
			{
				StringBuilder result = new StringBuilder();
				foreach (FieldInfo field in typeof(ConfigSettings).GetFields())
				{
					IFormattable formattable = field.GetValue(settingsToWrite) as IFormattable;
					string value = formattable == null ? field.GetValue(settingsToWrite).ToString() : formattable.ToString(null, CultureInfo.InvariantCulture);
					result.AppendFormat(CultureInfo.InvariantCulture, "{0}={1}\n", field.Name, value);
				}
				return result.ToString();
			}
		}
	}
}
