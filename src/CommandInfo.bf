using System;
using System.Collections;

namespace CowieCLI
{
	public class CommandInfo
	{
		public String About = new .() ~ delete _;
		public List<CommandOption> Options = new .() ~ DeleteContainerAndItems!(_);

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
	}
}
