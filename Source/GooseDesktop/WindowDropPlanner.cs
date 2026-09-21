using System;
using System.Collections.Generic;
using System.Drawing;

namespace GooseDesktop
{
	internal sealed class WindowDropPlanner
	{
		private readonly Random random;
		private readonly Queue<int> recentZones = new Queue<int>();

		internal WindowDropPlanner(Random randomSource)
		{
			if (randomSource == null) throw new ArgumentNullException("randomSource");
			random = randomSource;
		}

		internal int LastChosenZone { get; private set; }

		internal Point ChooseWindowDropPosition(Size desktopSize, Size windowSize, int columns, int rows, int edgeMargin, bool avoidRecentZones)
		{
			columns = Math.Max(1, Math.Min(10, columns));
			rows = Math.Max(1, Math.Min(10, rows));
			edgeMargin = Math.Max(0, edgeMargin);

			int zone = ChooseDropZone(columns * rows, avoidRecentZones);
			LastChosenZone = zone;
			int column = zone % columns;
			int row = zone / columns;
			float zoneWidth = desktopSize.Width / (float)columns;
			float zoneHeight = desktopSize.Height / (float)rows;

			int minimumCenterX = Math.Max(edgeMargin + windowSize.Width / 2, (int)Math.Ceiling(column * zoneWidth));
			int maximumCenterX = Math.Min(desktopSize.Width - edgeMargin - (windowSize.Width - windowSize.Width / 2), (int)Math.Floor((column + 1) * zoneWidth));
			int minimumCenterY = Math.Max(edgeMargin + windowSize.Height / 2, (int)Math.Ceiling(row * zoneHeight));
			int maximumCenterY = Math.Min(desktopSize.Height - edgeMargin - (windowSize.Height - windowSize.Height / 2), (int)Math.Floor((row + 1) * zoneHeight));

			int centerX = ChooseCoordinate(minimumCenterX, maximumCenterX, desktopSize.Width / 2);
			int centerY = ChooseCoordinate(minimumCenterY, maximumCenterY, desktopSize.Height / 2);
			Point candidate = new Point(centerX - windowSize.Width / 2, centerY - windowSize.Height / 2);
			return ClampWindowTarget(candidate, desktopSize, windowSize, edgeMargin);
		}

		internal static Point ClampWindowTarget(Point target, Size desktopSize, Size windowSize, int edgeMargin)
		{
			int safeMarginX = Math.Min(Math.Max(0, edgeMargin), Math.Max(0, (desktopSize.Width - windowSize.Width) / 2));
			int safeMarginY = Math.Min(Math.Max(0, edgeMargin), Math.Max(0, (desktopSize.Height - windowSize.Height) / 2));
			int maximumX = Math.Max(safeMarginX, desktopSize.Width - windowSize.Width - safeMarginX);
			int maximumY = Math.Max(safeMarginY, desktopSize.Height - windowSize.Height - safeMarginY);
			return new Point(Math.Max(safeMarginX, Math.Min(maximumX, target.X)), Math.Max(safeMarginY, Math.Min(maximumY, target.Y)));
		}

		private int ChooseDropZone(int zoneCount, bool avoidRecentZones)
		{
			List<int> choices = new List<int>();
			for (int zone = 0; zone < zoneCount; zone++)
			{
				if (!avoidRecentZones || !recentZones.Contains(zone)) choices.Add(zone);
			}
			if (choices.Count == 0)
			{
				for (int zone = 0; zone < zoneCount; zone++)
				{
					if (recentZones.Count == 0 || zone != LastChosenZone) choices.Add(zone);
				}
			}
			if (choices.Count == 0) choices.Add(0);

			int selected = choices[random.Next(choices.Count)];
			recentZones.Enqueue(selected);
			while (recentZones.Count > 2) recentZones.Dequeue();
			return selected;
		}

		private int ChooseCoordinate(int minimum, int maximum, int fallback)
		{
			if (maximum < minimum) return fallback;
			if (maximum == minimum) return minimum;
			return random.Next(minimum, maximum + 1);
		}
	}
}
