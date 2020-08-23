using System;
using System.Collections;
using System.Reflection;

namespace CowieCLI
{
	/*
	Option types:
		Short flag option (bool): -q -> bool quiet = true (false if option is not present)
		Verbose flag option (bool): --quiet -> bool quiet = true (false if option is not present)
		Option with value (String): --letters abc -> String letters = "abc" (Empty string if option is not present)
		Option with multiple values (List<String>): --letters a b c -> List<String> letters = { "a", "b", "c" } (Empty list if option is not present)
	*/
	public class CowieCLI
	{
		public List<CommandEntry> Commands = new .() ~ DeleteContainerAndItems!(_);

		public static Verbosity CurrentVerbosity = .Normal;

		public String HelpMessage;
		public Type DefaultCommand = null;

		public  void Init(String helpMessage = "")
		{
			HelpMessage = helpMessage;
		}

		public  void Init<TDefaultCommand>(String helpMessage = "") where TDefaultCommand : ICommand
		{
			DefaultCommand = typeof(TDefaultCommand);
			Init(helpMessage);
		}

		public  void Help(ICommand command = null)
		{
			if (command == null)
				Console.WriteLine(HelpMessage);
			else
				Console.WriteLine(command.Info.About);
		}

		/*private  CommandCall ParseCall(Span<String> args)
		{
			if (args.Length == 0)
			{
				Help();
				return null;
			}

			CommandCall call = new .();

			if (IsCommand(args[0]))
				call.Command.Set(args[0]);
			else
				FatalError("Unknown command: {}", args[0]);

			for (var arg in args)
			{
				// Option
				if (arg.StartsWith('-'))
					call.AddOption(arg);
				// Value
				else
					call.AddOption(arg);
			}
			
			return call;

			bool IsMultiCommand(StringView arg)
			{
				for (var char in arg)
					if (!char.IsLetter && char != '+')
						return false;
				return true;
			}
		}*/

		/*public  void Run(Span<String> args)
		{
			var call = ParseCall(args);
			ICommand command = null;

			let result = GetCommand(call.Command);
			if (result case .Ok(let commandInstance))
			{
				if (commandInstance == null)
					return;
				command = commandInstance;
			}

			CurrentVerbosity = .Normal;

			for (let option in call.Options)
			{
				switch (option)
				{
				case "--debug", "-d":
					CurrentVerbosity = .Debug;
					call.Options.DeleteAndRemove(option);
					break;
				case "--verbose", "-v":
					CurrentVerbosity = .Verbose;
					call.Options.DeleteAndRemove(option);
					break;
				case "--quiet", "-q":
					CurrentVerbosity = .Quiet;
					call.Options.DeleteAndRemove(option);
					break;
				}
			}

			for (let option in command.Info.Options)
			{
				var fieldResult = GetField(option.Name);
				if (fieldResult case .Ok(let field))
				{
					switch (field.FieldType)
					{
					case typeof(String):
						var actualOption = GetStringOption(option.Name, option.Short);
						if (actualOption == "" && option.IsRequired)
							FatalError("Option {} is required", option);

						field.SetValue(command, actualOption);
						break;
					case typeof(List<String>):
						var optionValues = GetMultipleOptions(option.Name, option.Short);
						if (optionValues.Count == 0 && option.IsRequired)
							FatalError("Option {} is required", option);

						field.SetValue(command, optionValues);
						for (var value in optionValues)
							call.Options.Remove(value);
						break;
					case typeof(bool):
						field.SetValue(command, GetOption(option.Name, option.Short));
						break;
					default:
						var typename = scope String();
						field.FieldType.GetName(typename);
						FatalError("Command option field '{}' has invalid type: {}", field.Name, typename);
					}

					RemoveOption(option.Name, option.Short);
				}
				else
					FatalError("Could not find field matching option: {}", option);
			}

			if (call.Options.Count == 1)
				FatalError("Unknown option: {}", call.Options[0]);
			else if (call.Options.Count > 1)
			{
				var str = scope String()..Join(", ", call.Options.GetEnumerator());
				FatalError("Unknown options: {}", str);
			}

			// Check requirements and conflicts
			for (let optionToCheck in command.Info.Options)
			{
				for (let option in command.Info.Options)
				{
					if (option == optionToCheck)
						continue;

					var field = GetField(option.Name).Get(); // Has already been proven in previous loop that it exists
					
					switch (field.FieldType)
					{
					case typeof(String):
						field.GetValue<String>(command, var value);

						if (value == "")
							CheckRequirement();

						if (value != "")
							CheckConflict();

						break;
					case typeof(List<String>):
						field.GetValue<List<String>>(command, var value);

						if (value.Count == 0)
							CheckRequirement();

						if (value.Count > 0)
							CheckConflict();

						break;
					case typeof(bool):
						field.GetValue<bool>(command, var value);

						if (!value)
							CheckRequirement();

						if (value)
							CheckConflict();

						break;
					}
				}
			}

			command.Execute();
			delete call;
			delete command;

			void CheckRequirement()
			{
				if (optionToCheck.Requirements.Contains(option.Name))
					FatalError("Option {} requires the {} option", optionToCheck, option);
			}

			void CheckConflict()
			{
				if (optionToCheck.Conflicts.Contains(option.Name))
					FatalError("Option {} conflicts with the {} option", optionToCheck, option);
			}	

			void RemoveOption(String verbose, String short)
			{
				for (var option in call.Options)
				{
					if (IsOption(option, verbose, short))
					{
						call.Options.DeleteAndRemove(option);
						break;
					}
				}
			}

			Result<FieldInfo> GetField(StringView name)
			{
				for (var field in command.GetType().GetFields())
					if (String.Compare(field.Name, name, true))
						return field;
				return .Err;
			}

			bool GetOption(String verbose, String short = "")
			{
				for (var option in call.Options)
				{
					if (IsOption(option, verbose, short))
						return true;
				}

				return false;
			}

			String GetStringOption(String verbose, String short = "")
			{
				var str = new String();
				var enumerator = call.Options.GetEnumerator();
				for (var option in enumerator)
				{
					if (IsOption(option, verbose, short))
					{
						if (enumerator.GetNext() case .Ok(let nextOption))
							str.Set(nextOption);
						else
							FatalError("Option {} has no value", option);
					}
				}

				return str;
			}

			List<String> GetMultipleOptions(String verbose, String short = "")
			{
				var enumerator = call.Options.GetEnumerator();
				var isOption = false;
				var containsOption = call.Options.Contains(verbose) || call.Options.Contains(short);
				var result = new List<String>();

				for (var option in enumerator)
				{
					if (!isOption)
					{
						if ((!containsOption && !option.StartsWith('-')) ||
							(containsOption && IsOption(option, verbose, short)))
							isOption = true;
						else
							continue;
					}
					
					if (option.StartsWith('-'))
						break;

					result.Add(option);
				}

				return result;
			}

			bool IsOption(String option, String verbose, String short = "")
			{
				if ((option.Length >= 3 && StringView(option, 2) == verbose) ||
					(option.Length >= 2 && StringView(option, 1) == short))
					return true;
				return false;
			}
		}*/

		public  void RegisterCommand<T>(StringView name) where T : ICommand
		{
			let entry = new CommandEntry(name, typeof(T));
			Commands.Add(entry);
		}

		public int Run(Span<String> args)
		{
			if (args.Length == 0)
			{
				Help();
				return 0;
			}

			let commandRes = GetCommand(args[0]);

			if (commandRes == .Err)
			{
				CowieCLI.Error("Command {} not found.", args[0]);
				return 1;
			}

			let command = commandRes.Value;
			let commandCall = ParseCommand(args, command);
			if (commandCall == .Err)
			{
				CowieCLI.Error("Invalid arguments");
				Help();
				return 1;
			}

			if (PopulateCommand(command, commandCall) case .Err)
			{
				CowieCLI.Error("Couldn't populate the command");
				return 2;
			}

			let res = command.Execute();

			delete commandCall.Value;
			delete command;

			return res;
		}

		private Result<void> PopulateCommand(ICommand command, CommandCall call)
		{
			for (let option in command.Info.Options)
			{
				var optionName = scope String(option.Name);

				if (!option.IsOptional && !call.HasOption(optionName))
				{
					CowieCLI.Error("Argument {} is required.", optionName);
					return .Err;
				}

				if (!call.HasOption(optionName))
				{
					continue;
				}

				String.Capitalized(optionName);
				var tempField = command.GetType().GetField(optionName);
				var tempProp = command.GetType().GetProperty(optionName);

				if ((tempField == .Err) && (tempProp == .Err))
				{
					CowieCLI.Error("Command {} has no field or property {}", option.Name, optionName);
					return .Err;
				}

				var field = (tempField != .Err) ? (tempField.Value) : (
					(tempProp != .Err) ? (tempProp.Value) : (default(FieldInfo))
				);

				if (field == default(FieldInfo))
				{
					CowieCLI.Error("Setting field {} failed", optionName);
					return .Err;
				}

				if (PopulateField(command, field, option, call.GetValues(option.Name)) case .Err)
				{
					CowieCLI.Error("Setting field {} failed", optionName);
					return .Err;
				}
			}
			return .Ok;
		}

		private Result<void> PopulateField(ICommand command, FieldInfo field, CommandOption option, List<String> values)
		{
			if (option.IsList)
			{
				return PopulateListField(command, field, values);
			}

			var res = Result<void, FieldInfo.Error>();
			switch (field.FieldType)
			{
			case typeof(String):
				res = field.SetValue(command, values[0]);
				break;
			case typeof(int):
				var value = Int.Parse(values[0]);
				res = field.SetValue(command, value);
				break;
			case typeof(float):
				var value = Float.Parse(values[0]);
				res = field.SetValue(command, value);
				break;
			default:
				CowieCLI.Error("Unsupported type: {}", field.FieldType);
				return .Err;
			}

			if (res != .Ok)
			{
				CowieCLI.Error("Error setting field {}.", field.Name);
				return .Err;
			}

			return .Ok;
		}

		private Result<void> PopulateListField(ICommand command, FieldInfo field, List<String> values)
		{
			var listType = field.FieldType as SpecializedGenericType;
			var paramType = listType.GetGenericArg(0);

			var fieldRef = field.GetValue(command).Value.Get<Object>();
			var addMethod = fieldRef.GetType().GetMethod("Add");

			switch (addMethod)
			{
			case .Err(let err):
				CowieCLI.Error("Cannot find method Add on field {}", field.Name);
				return .Err;
			default:
				break;
			}

			var res = Result<Variant, MethodInfo.CallError>();
			for (var value in values)
			{
				switch (paramType)
				{
				case typeof(String):
					res = addMethod.Get().Invoke(fieldRef, value);
					break;
				case typeof(int):
					var val = Int.Parse(value);
					res = addMethod.Get().Invoke(fieldRef, val);
					break;
				case typeof(float):
					var val = Float.Parse(value);
					res = addMethod.Get().Invoke(fieldRef, val);
					break;
				default:
					CowieCLI.Error("Unsupported type: {}", field.FieldType);
					return .Err;
				}

				switch (res)
				{
				case .Err(let err):
					CowieCLI.Error("Error setting field {}.", field.Name);
					return .Err;
				case .Ok(let val):
					break;
				}
			}

			return .Ok;
		}

		private Result<CommandCall> ParseCommand(Span<String> args, ICommand command)
		{
			var call = new CommandCall();
			var validArg = true;
			var optionsParsed = 0;

			// We start as 1 because 0 is the name of the command that should have been parsed
			// prior to arriving here.
			for (int i = 1; i < args.Length; i++)
			{
				var arg = args[i];
				var namedArg = scope String();
				if (!command.HasNamedOption(arg))
				{
					validArg = false;
				}
				else
				{
					namedArg = arg;
					namedArg.Remove(0, 2);
				}

				if (!validArg && arg.StartsWith('-'))
				{
					return .Err;
				}

				if ((optionsParsed >= command.Info.Options.Count) && !validArg)
				{
					return .Err;
				}
				else
				{
					var values = scope List<String>();
					CommandOption option = default;

					if (namedArg.IsEmpty)
					{
						option = command.Info.Options[optionsParsed++];
						ParseArgument(args[i], option, values);
					}
					else
					{
						option = command.Info.GetNamedOption(namedArg);
						ParseArgument(args[i + 1], option, values);
						i++;
					}

					call.AddOption(option.Name, values);
				}
			}

			return call;
		}

		private void ParseArgument(String arg, CommandOption option, List<String> values)
		{
			if (option.IsList)
			{
				if (arg.Contains(','))
				{
					var vals = arg.Split(',');
					for (var v in vals)
					{
						values.Add(new String(v));
					}
				}
			}
			else
			{
				values.Add(arg);
			}
		}

		private Result<ICommand> GetCommand(StringView name)
		{
			for (var entry in Commands)
			{
				if (entry.Name == name)
					return entry.Instantiate();
			}

			return .Err;
		}

		public  bool IsCommand(StringView name)
		{
			for (var entry in Commands)
				if (entry.Name == name)
					return true;
			return false;
		}

		public  bool Ask(StringView text)
		{
			bool DoAsk()
			{
				while (true)
				{
					Console.Write("{} [y/n] ", text);
					let char = Console.ReadKey();
					if (char == 'y')
						return true;
					else if (char == 'n')
						return false;
				}
			}

			bool answer = DoAsk();
			let length = 19 + text.Length;
			Console.EmptyLine(length);
			return answer;
		}

		public static void Success(StringView fmt, params Object[] args) => Print(.Green, true, scope String()..AppendF("[Success] {}", fmt), params args);
		public static void Info(StringView fmt, params Object[] args) => Print(.Cyan, true, scope String()..AppendF("[Info] {}", fmt), params args);
		public static void Warning(StringView fmt, params Object[] args) => Print(.Yellow, true, scope String()..AppendF("[Warning] {}", fmt), params args);
		public static void Error(StringView fmt, params Object[] args) => Print(.Red, true, scope String()..AppendF("[Error] {}", fmt), params args);
		public static void FatalError(StringView fmt, params Object[] args)
		{
			Error(fmt, params args);
#if DEBUG
			Console.Write("Press any key to exit...");
			Console.ReadKey();
#endif
			Internal.FatalError(scope String()..AppendF(fmt, params args));
		}

		public static void Print(bool newline, String fmt, params Object[] args) => Print(.White, newline, fmt, params args);
		public static void Print(ConsoleColor color, bool newline, String fmt, params Object[] args)
		{
			if (CurrentVerbosity == .Quiet)
				return;

			let origin = Console.ForegroundColor;
			Console.ForegroundColor = color;

			Console.Write(fmt, params args);
			if (newline)
				Console.WriteLine();

			Console.ForegroundColor = origin;
		}
	}
}
