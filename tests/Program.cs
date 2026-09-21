using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;

namespace GooseDesktop
{
	internal static class Program
	{
		private static int assertions;

		private static void Main()
		{
			TestZoneSelectionAndClamping();
			TestSmallDesktopClamping();
			TestOldAndInvalidConfigCompatibility();
			Console.WriteLine("Window drop/config tests passed ({0} assertions).", assertions);
		}

		internal static string GetPathToFileInAssembly(string relativePath)
		{
			return Path.Combine(AppContext.BaseDirectory, relativePath);
		}

		private static void TestZoneSelectionAndClamping()
		{
			WindowDropPlanner planner = new WindowDropPlanner(new Random(12345));
			Size desktop = new Size(1920, 1080);
			Size window = new Size(400, 400);
			HashSet<int> observedZones = new HashSet<int>();
			int previous = -1;

			for (int i = 0; i < 200; i++)
			{
				Point point = planner.ChooseWindowDropPosition(desktop, window, 3, 3, 50, true);
				Assert(point.X >= 50 && point.Y >= 50, "position respects the top/left margin");
				Assert(point.X + window.Width <= desktop.Width - 50, "window respects the right margin");
				Assert(point.Y + window.Height <= desktop.Height - 50, "window respects the bottom margin");
				Assert(planner.LastChosenZone != previous, "consecutive zones differ");
				observedZones.Add(planner.LastChosenZone);
				previous = planner.LastChosenZone;
			}

			Assert(observedZones.Count == 9, "all nine zones are reachable");
		}

		private static void TestSmallDesktopClamping()
		{
			Point point = WindowDropPlanner.ClampWindowTarget(new Point(-1000, 5000), new Size(300, 200), new Size(400, 400), 50);
			Assert(point.X == 0 && point.Y == 0, "oversized windows clamp to the available origin");
		}

		private static void TestOldAndInvalidConfigCompatibility()
		{
			string tempFile = Path.Combine(Path.GetTempPath(), "goose-prank-config-" + Guid.NewGuid().ToString("N") + ".ini");
			try
			{
				File.WriteAllText(tempFile,
					"Version_DoNotEdit=1\nEnableMods=False\nTask_CanAttackMouse=True\nAttackRandomly=False\n" +
					"MinWanderingTimeSeconds=-20\nMaxWanderingTimeSeconds=not-a-number\nWindowDropGridColumns=99\n");
				GooseConfig.ConfigSettings config = GooseConfig.ConfigSettings.ReadFileIntoConfig(tempFile);
				Assert(config.Task_CanAttackMouse, "stock attack key loads");
				Assert(!config.AttackRandomly, "stock random-attack key loads");
				Assert(config.MinWanderingTimeSeconds == 1f, "invalid low wander time is clamped");
				Assert(config.MaxWanderingTimeSeconds == 15f, "malformed value retains its default");
				Assert(config.WindowDropGridColumns == 10, "oversized grid is clamped");
				Assert(config.WindowDropGridRows == 3, "missing custom keys retain defaults");
				Assert(config.EnableTeleporters, "missing teleporter key retains its enabled default");
				Assert(config.EnableVehicles, "missing vehicle key retains its enabled default");
			}
			finally
			{
				if (File.Exists(tempFile)) File.Delete(tempFile);
			}
		}

		private static void Assert(bool condition, string message)
		{
			assertions++;
			if (!condition) throw new InvalidOperationException("Assertion failed: " + message);
		}
	}
}
