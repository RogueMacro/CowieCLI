namespace System
{
	extension String
	{
		public static bool Compare(StringView strA, StringView strB, bool ignoreCase)
		{
			if (ignoreCase)
				return CompareOrdinalIgnoreCaseHelper(strA.Ptr, strA.Length, strB.Ptr, strB.Length) == 0;
			return CompareOrdinalHelper(strA.Ptr, strA.Length, strB.Ptr, strB.Length) == 0;
		}
	}

	extension Console
	{
		public static void EmptyLine(int length)
		{
			Console.Write('\r');
			for (int i = 0; i < length; ++i)
				Console.Write(' ');
			Console.Write('\r');
		}

		public static char8 ReadKey()
		{
			return getch();
		}

		[Import("kernel32.lib"), CLink]
		private static extern char8 getch();
	}
}

namespace System.Collections
{
	extension List<T> where T : delete
	{
		public bool DeleteAndRemove(T item)
		{
			int index = IndexOf(item);
			if (index >= 0)
			{
				delete this[index];
				RemoveAt(index);
				return true;
			}

			return false;
		}
	}
}
