using System;
using System.Collections;

namespace CowieCLI
{
	public class CommandInfo
	{
		public String Name = new .() ~ delete _;
		public String About = new .() ~ delete _;
		public List<CommandOption> Options = new .() ~ DeleteContainerAndItems!(_);

		public Self Name(StringView name)
		{
			Name.Set(name);
			return this;
		}

		public Self About(StringView about)
		{
			About.Set(about);
			return this;
		}

		public Self Option(CommandOption option)
		{
			Options.Add(option);
			return this;
		}

		public CommandOption GetNamedOption(String name)
		{
			for (var option in Options)
			{
				if (option.Name == name)
				{
					return option;
				}
			}

			return null;
		}
	}
}
