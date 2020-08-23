using System;
using System.Collections;

namespace CowieCLI
{
	public class CommandCall
	{
		//public String OptionName = new .() ~ delete _;
		//public List<String> Options = new .() ~ DeleteContainerAndItems!(_);
		public Dictionary<String, List<String>> Values = new .();
		public String InvalidArgument = new .() ~ delete _;

		public ~this()
		{
			if (Values != null)
			{
				for (var value in Values)
				{
					delete value.key;
					DeleteContainerAndItems!(value.value);
				}
				delete Values;
			}
		}

		public void AddOption(StringView name, List<String> options)
		{
			let opts = new List<String>();
			opts.AddRange(options);

			Values.Add(new String(name), opts);
		}

		public bool HasOption(StringView name)
		{
			for (var key in Values.Keys)
			{
				if (key.Equals(scope String(name)))
				{
					return true;
				}
			}

			return false;
		}

		public List<String> GetValues(String optionName)
		{
			return Values[optionName];
		}
		//public void AddOption(StringView option) => Options.Add(new String()..Set(option));
	}
}
