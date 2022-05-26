using System.IO;
using UnrealBuildTool;
 
public class NimForUETest : ModuleRules
{
	public NimForUETest(ReadOnlyTargetRules Target) : base(Target)
	{
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
		PublicDependencyModuleNames.AddRange(new string[] {
			"Core", 
			"CoreUObject", 
			"Engine", 
			"UnrealEd",
			"NimForUEBindings"
		});
		PrivateDependencyModuleNames.AddRange(new string[] {  });
		var nimHeadersPath = Path.Combine(PluginDirectory, "NimHeaders");
		PublicIncludePaths.Add(nimHeadersPath);
	}
}