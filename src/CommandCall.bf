using System;
using System.Collections;

namespace CowieCLI
{
	public class CommandCall
	{
		public String Command = new .() ~ delete _;
		public List<String> Options = new .() ~ DeleteContainerAndItems!(_);

		public void AddOption(StringView option) => Options.Add(new String()..Set(option));
	}
}