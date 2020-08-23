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

		public void Help(String progName)
		{
			Console.WriteLine("{} {}", progName, Info.Name);
			Console.WriteLine("Description: {}", Info.About);
			Console.WriteLine("Usage: {} {} [<args>...] [options...]", progName, Info.Name);

			Console.WriteLine("\nArguments:");
			for (var opt in Info.Options)
			{
				if (!opt.IsOptional)
				{
					var shortStr = scope String();
					if (!opt.ShortName.IsEmpty)
					{
						shortStr.AppendF(", -{}", opt.ShortName);
					}

					var optArgs = scope String();
					var separatorStr = scope String();
					if (opt.IsList)
					{
						optArgs.AppendF("<{}...>", opt.Name);
						if (opt.CharSep.IsWhiteSpace)
						{
							separatorStr.AppendF("spaces.\n\t\t\t\t\tParsing will continue until reaching a named option or the end of the command", opt.CharSep);
						}
						else
						{
							separatorStr.AppendF("the character '{}'", opt.CharSep);
						}
					}
					else
					{
						optArgs.AppendF("<{}>", opt.Name);
					}

					Console.WriteLine("  --{}{}\t{}\t\t{}", opt.Name, shortStr, optArgs, opt.Description);
					Console.WriteLine("\t\t\t\t\tAccepts a list of {} separated by {}.", opt.Name, separatorStr);
				}
			}

			Console.WriteLine("\n\nOptions:");

			for (var opt in Info.Options)
			{
				if (!opt.IsOptional)
				{
					continue;
				}

				var shortStr = scope String();
				if (!opt.ShortName.IsEmpty)
				{
					shortStr.AppendF(", -{}", opt.ShortName);
				}

				var optArgs = scope String();
				if (opt.IsList)
				{
					optArgs.AppendF("<{}...>", opt.Name);
				}
				else
				{
					optArgs.AppendF("<{}>", opt.Name);
				}

				Console.WriteLine("  --{}{}\t{}\t{}", opt.Name, shortStr, optArgs, opt.Description);
				if (opt.IsList)
				{
					var separatorStr = scope String();
					if (opt.CharSep.IsWhiteSpace)
					{
						separatorStr.AppendF("spaces. Parsing will continue until reaching a named option or the end of the command", opt.CharSep);
					}
					else
					{
						separatorStr.AppendF("the character '{}'", opt.CharSep);
					}
					Console.WriteLine("\t\t\t\tAccepts a list of {} separated by {}.", opt.Name, separatorStr);
				}
			}
		}
	}
}
