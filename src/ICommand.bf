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
					if (option.Name.Equals(scope String(&name[2])))
					{
						return true;
					}
				}
				else if (name.StartsWith('-') && (name[1] != '-'))
				{
					if (option.ShortName.Equals(scope String(&name[1])))
					{
						return true;
					}
				}
			}

			return false;
		}
	}
}
