using System;

namespace CowieCLI
{
	public class CommandEntry
	{
		public String Name = new .() ~ delete _;
		public Type Type;

		public this(StringView name, Type type)
		{
			if (type.IsSubtypeOf(typeof(ICommand)))
			{
				Name.Set(name);
				Type = type;
			}
			else
			{
				var typename = scope String();
				type.GetFullName(typename);
				CowieCLI.Error("Invalid CommandEntry: Name = {}, Type = {}", name, typename);
			}
		}

		public ICommand Instantiate()
		{
			let result = this.Type.CreateObject();
			if (result case .Ok(let val))
				return (.) result.Get();

			CowieCLI.Error("Could not instantiate command ({})", Name);
			return null;
		}
	}
}
