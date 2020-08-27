using System;

namespace CowieCLI
{
	public abstract class ICommand
	{
		public abstract CommandInfo Info { get; }
		public abstract int Execute();

		public bool HasNamedOption(StringView name)
		{
			for (var option in Info.Options)
			{
				if (name.StartsWith("--"))
				{
					var optionName = scope String(name, 2, name.Length - 2);
					if (option.Name.Equals(optionName))
					{
						return true;
					}
				}
				else if (name.StartsWith('-') && (name[1] != '-'))
				{
					var optionName = scope String(name, 1, 1);
					if (option.ShortName.Equals(optionName))
					{
						return true;
					}
				}
			}

			return false;
		}
	}
}
