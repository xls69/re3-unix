newoption {
	trigger     = "with-asan",
	description = "Build with address sanitizer"
}

newoption {
	trigger     = "with-librw",
	description = "Build and use librw from this solution"
}

newoption {
	trigger     = "with-lto",
	description = "Build with link time optimization"
}

newoption {
	trigger     = "no-git-hash",
	description = "Don't print git commit hash into binary"
}

newoption {
	trigger     = "no-full-paths",
	description = "Don't print full paths into binary"
}

require("autoconf")

if(_OPTIONS["with-librw"]) then
	Librw = "vendor/librw"
end

function getarch(a)
	if a == 'x86_64' then
		return 'amd64'
	elseif a == 'ARM' then
		return 'arm'
	elseif a == 'ARM64' then
		return 'arm64'
	end
	return a
end

local function dependencyincludedirs(paths)
	if _ACTION == "xcode4" then
		externalincludedirs(paths)
	else
		includedirs(paths)
	end
end

local macosxHomebrewPrefix = os.getenv("HOMEBREW_PREFIX")
if not macosxHomebrewPrefix or macosxHomebrewPrefix == "" then
	macosxHomebrewPrefix = os.host() == "macosx" and os.hostarch() == "ARM64" and "/opt/homebrew" or "/usr/local"
end

local function resolveMacosxDependencyDylib(formula, filename, homebrewPrefix)
	local candidates = {
		path.join("/opt/local/lib", filename),
		path.join(homebrewPrefix, "opt", formula, "lib", filename),
	}

	for _, candidate in ipairs(candidates) do
		if os.isfile(candidate) then
			return candidate
		end
	end
	return candidates[2]
end

local macosxDependencies = {
	{ formula = "openal-soft", filename = "libopenal.1.dylib" },
	{ formula = "mpg123", filename = "libmpg123.0.dylib" },
	{ formula = "glfw", filename = "libglfw.3.dylib" },
}

local function resolveMacosxDependencyDylibs(homebrewPrefix)
	local dylibs = {}
	for _, dependency in ipairs(macosxDependencies) do
		table.insert(dylibs, {
			filename = dependency.filename,
			path = resolveMacosxDependencyDylib(dependency.formula, dependency.filename, homebrewPrefix),
		})
	end
	return dylibs
end

local macosxDependencyDylibs = resolveMacosxDependencyDylibs(macosxHomebrewPrefix)
local macosxArm64HomebrewPrefix = os.hostarch() == "ARM64" and macosxHomebrewPrefix or "/opt/homebrew"
local macosxAmd64HomebrewPrefix = os.hostarch() == "ARM64" and "/usr/local" or macosxHomebrewPrefix
local macosxArm64DependencyDylibs = resolveMacosxDependencyDylibs(macosxArm64HomebrewPrefix)
local macosxAmd64DependencyDylibs = resolveMacosxDependencyDylibs(macosxAmd64HomebrewPrefix)

local function existingDirectories(directories)
	local existing = {}
	for _, directory in ipairs(directories) do
		if os.isdir(directory) then
			table.insert(existing, directory)
		end
	end
	return existing
end

local function existingXcodeSearchPaths(directories)
	local existing = existingDirectories(directories)
	table.insert(existing, 1, "$(inherited)")
	return existing
end

local macosxXcodeArchitectures = _OPTIONS["arch"]
if not macosxXcodeArchitectures or macosxXcodeArchitectures == "universal" then
	macosxXcodeArchitectures = "$(ARCHS_STANDARD)"
end

local macosxXcodeDeploymentTarget = macosxXcodeArchitectures == "x86_64" and "10.12" or "11.0"
local macosxXcodeBuildSettings = {
	["ARCHS"] = { macosxXcodeArchitectures },
	["MACOSX_DEPLOYMENT_TARGET"] = { macosxXcodeDeploymentTarget },
	["ONLY_ACTIVE_ARCH"] = { "YES" },
}
if macosxXcodeArchitectures == "$(ARCHS_STANDARD)" then
	macosxXcodeBuildSettings["MACOSX_DEPLOYMENT_TARGET[arch=x86_64]"] = { "10.12" }
end

local function macosxDependencyPaths(dylibs)
	local paths = {}
	for _, dylib in ipairs(dylibs) do
		table.insert(paths, dylib.path)
	end
	return paths
end

local function macosxDependencyFilenames(dylibs)
	local filenames = {}
	for _, dylib in ipairs(dylibs) do
		table.insert(filenames, dylib.filename)
	end
	return filenames
end

local function macosxInstallNameCommands(dylibs, executable)
	local commands = {}
	for _, dylib in ipairs(dylibs) do
		table.insert(commands, 'install_name_tool -change "' .. dylib.path .. '" "@rpath/' .. dylib.filename .. '" "' .. executable .. '"')
	end
	return commands
end

local function macosxGmakeBundleCommands(dylibs)
	local commands = {}
	for _, dylib in ipairs(dylibs) do
		table.insert(commands, '{COPYFILE} "' .. dylib.path .. '" "%{cfg.targetdir}/re3.app/Contents/Frameworks/' .. dylib.filename .. '"')
	end
	for _, command in ipairs(macosxInstallNameCommands(dylibs, "%{cfg.targetdir}/re3.app/Contents/MacOS/re3")) do
		table.insert(commands, command)
	end
	for _, dylib in ipairs(dylibs) do
		table.insert(commands, 'codesign --force --sign - "%{cfg.targetdir}/re3.app/Contents/Frameworks/' .. dylib.filename .. '"')
	end
	table.insert(commands, 'codesign --force --sign - "%{cfg.targetdir}/re3.app"')
	return commands
end

workspace "re3"
	language "C++"
	configurations { "Debug", "Release", "Custom" }
	startproject "re3"
	location "build"
	symbols "Full"
	staticruntime "off"

	if _OPTIONS["with-asan"] then
		buildoptions { "-fsanitize=address -g3 -fno-omit-frame-pointer" }
		linkoptions { "-fsanitize=address" }
	end

	filter { "system:linux" }
		platforms {
			"linux-x86-librw_gl3_glfw-oal",
			"linux-amd64-librw_gl3_glfw-oal",
			"linux-arm-librw_gl3_glfw-oal",
			"linux-arm64-librw_gl3_glfw-oal",
		}

	filter { "system:bsd" }
		platforms {
			"bsd-x86-librw_gl3_glfw-oal",
			"bsd-amd64-librw_gl3_glfw-oal",
			"bsd-arm-librw_gl3_glfw-oal",
			"bsd-arm64-librw_gl3_glfw-oal"
		}

	filter { "system:macosx" }
		cppdialect "gnu++14"
		if _ACTION == "xcode4" then
			platforms { "macosx-librw_gl3_glfw-oal" }
		else
			platforms {
				"macosx-arm64-librw_gl3_glfw-oal",
				"macosx-amd64-librw_gl3_glfw-oal",
			}
		end

	filter "configurations:Debug"
		defines { "DEBUG" }

	filter "configurations:not Debug"
		defines { "NDEBUG" }
		optimize "Speed"
		if(_OPTIONS["with-lto"]) then
			flags { "LinkTimeOptimization" }
		end
	
	filter "configurations:Custom"
		defines { "NDEBUG", "CUSTOM" }
		optimize "Speed"
		if(_OPTIONS["with-lto"]) then
			flags { "LinkTimeOptimization" }
		end


	filter { "platforms:linux*" }
		system "linux"

	filter { "platforms:bsd*" }
		system "bsd"

	filter { "platforms:macosx*" }
		system "macosx"

	filter { "platforms:*x86*" }
		architecture "x86"

	filter { "platforms:*amd64*" }
		architecture "amd64"

	filter { "platforms:*arm-*" }
		architecture "ARM"

	filter { "platforms:*arm64*" }
		architecture "ARM64"

	filter { "platforms:macosx-arm64-*", "action:not xcode4" }
		buildoptions { "-target", "arm64-apple-macos11" }
		linkoptions { "-target", "arm64-apple-macos11" }

	filter { "platforms:macosx-amd64-*", "action:not xcode4" }
		buildoptions { "-target", "x86_64-apple-macos10.12" }
		linkoptions { "-target", "x86_64-apple-macos10.12" }

	filter { "system:macosx", "action:xcode4" }
		xcodebuildsettings(macosxXcodeBuildSettings)

	filter "platforms:*librw_gl3_glfw*"
		defines { "RW_GL3", "LIBRW_GLFW" }
		if(not _OPTIONS["with-librw"]) then
			libdirs { path.join(Librw, "lib/%{getsys(cfg.system)}-%{getarch(cfg.architecture)}-gl3/%{cfg.buildcfg}") }
		end

	filter  {}

    function setpaths (gamepath, exepath)
       if (gamepath) then
          postbuildcommands {
             '{COPYFILE} "%{cfg.buildtarget.abspath}" "' .. gamepath .. '%{cfg.buildtarget.name}"'
          }
          debugdir (gamepath)
          if (exepath) then
			 -- Used VS variable $(TargetFileName) because it doesn't accept premake tokens. Does debugcommand even work outside VS??
             debugcommand (gamepath .. "$(TargetFileName)")
             dir, file = exepath:match'(.*/)(.*)'
             debugdir (gamepath .. (dir or ""))
          end
       end
    end

if(_OPTIONS["with-librw"]) then
project "librw"
	kind "StaticLib"
	targetname "rw"
	if _ACTION == "xcode4" then
		targetdir "${BUILD_DIR}/%{cfg.buildcfg}"
		xcodebuildsettings {
			["SKIP_INSTALL"] = "YES",
		}
	else
		targetdir(path.join(Librw, "lib/%{cfg.platform}/%{cfg.buildcfg}"))
	end

	files { path.join(Librw, "src/*.*") }
	files { path.join(Librw, "src/*/*.*") }
	files { path.join(Librw, "src/gl/*/*.*") }

	filter { "platforms:*x86*" }
		architecture "x86"

	filter { "platforms:*amd64*" }
		architecture "amd64"

	filter "platforms:bsd*"
		includedirs { "/usr/local/include" }
		libdirs { "/usr/local/lib" }

	-- Support MacPorts and Homebrew
	filter "platforms:macosx-arm64-*"
		dependencyincludedirs { "/opt/local/include", "/opt/homebrew/include" }
		libdirs { "/opt/local/lib", "/opt/homebrew/lib" }

	filter "platforms:macosx-amd64-*"
		dependencyincludedirs { "/opt/local/include", "/usr/local/include" }
		libdirs { "/opt/local/lib", "/usr/local/lib" }

	filter { "system:macosx", "action:xcode4" }
		dependencyincludedirs { "/opt/local/include", "/opt/homebrew/include", "/usr/local/include" }
		xcodebuildsettings {
			["LIBRARY_SEARCH_PATHS[arch=arm64]"] = { "$(inherited)", "/opt/local/lib", "/opt/homebrew/lib" },
			["LIBRARY_SEARCH_PATHS[arch=x86_64]"] = { "$(inherited)", "/opt/local/lib", "/usr/local/lib" },
		}
		
	filter "platforms:*gl3_glfw*"
		staticruntime "off"

	filter  {}
end

local function addSrcFiles( prefix )
	return prefix .. "/*cpp", prefix .. "/*.h", prefix .. "/*.c", prefix .. "/*.ico", prefix .. "/*.rc"
end

project "re3"
	kind "WindowedApp"
	targetname "re3"
	if _ACTION == "xcode4" then
		targetdir "${BUILD_DIR}/%{cfg.buildcfg}"
	else
		targetdir "bin/%{cfg.platform}/%{cfg.buildcfg}"
	end

	filter { "system:macosx" }
		files { "res/images/re3.icns", "res/macos/Info.plist", "res/macos/ThirdPartyNotices.txt" }

	filter { "system:macosx", "action:xcode4" }
		xcodebuildresources { "res/macos/ThirdPartyNotices.txt" }
		xcodebuildsettings {
			["PRODUCT_BUNDLE_IDENTIFIER"] = "io.github.mrxenginner.re3",
			["INSTALL_PATH"] = "$(LOCAL_APPS_DIR)",
			["CODE_SIGN_STYLE"] = "Automatic",
			["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/../Frameworks",
		}
		links(macosxDependencyPaths(macosxDependencyDylibs))
		links { "pthread" }
		embedAndSign(macosxDependencyFilenames(macosxDependencyDylibs))
		postbuildcommands {
			'{MKDIR} "%{cfg.targetdir}/re3.app/Contents/Resources"',
			'{COPYFILE} "%{prj.location}/../LICENSE.md" "%{cfg.targetdir}/re3.app/Contents/Resources/LICENSE"',
			'{RMDIR} "%{cfg.targetdir}/re3.app/Contents/Resources/gamefiles"',
			'{COPYDIR} "%{prj.location}/../gamefiles" "%{cfg.targetdir}/re3.app/Contents/Resources"',
		}
		postbuildcommands(macosxInstallNameCommands(macosxDependencyDylibs, "${TARGET_BUILD_DIR}/${EXECUTABLE_PATH}"))

	filter { "system:macosx", "action:xcode4", "configurations:Release" }
		xcodebuildsettings {
			["CODE_SIGN_IDENTITY"] = "Apple Development",
			["ENABLE_HARDENED_RUNTIME"] = "YES",
		}

	filter { "system:macosx", "action:gmake*" }
		linkoptions { "-Wl,-rpath,@executable_path/../Frameworks" }
		postbuildcommands {
			'{MKDIR} "%{cfg.targetdir}/re3.app/Contents/MacOS"',
			'{MKDIR} "%{cfg.targetdir}/re3.app/Contents/Frameworks"',
			'{MKDIR} "%{cfg.targetdir}/re3.app/Contents/Resources"',
			'{COPYFILE} "%{cfg.buildtarget.abspath}" "%{cfg.targetdir}/re3.app/Contents/MacOS/re3"',
			'{COPYFILE} "%{prj.location}/../res/images/re3.icns" "%{cfg.targetdir}/re3.app/Contents/Resources/re3.icns"',
			'{COPYFILE} "%{prj.location}/../res/macos/ThirdPartyNotices.txt" "%{cfg.targetdir}/re3.app/Contents/Resources/ThirdPartyNotices.txt"',
			'{COPYFILE} "%{prj.location}/../LICENSE.md" "%{cfg.targetdir}/re3.app/Contents/Resources/LICENSE"',
			'{COPYFILE} "%{prj.location}/../res/macos/Info.plist" "%{cfg.targetdir}/re3.app/Contents/Info.plist"',
			'{RMDIR} "%{cfg.targetdir}/re3.app/Contents/Resources/gamefiles"',
			'{COPYDIR} "%{prj.location}/../gamefiles" "%{cfg.targetdir}/re3.app/Contents/Resources"',
		}

	filter { "action:gmake*", "platforms:macosx-arm64-*" }
		postbuildcommands(macosxGmakeBundleCommands(macosxArm64DependencyDylibs))

	filter { "action:gmake*", "platforms:macosx-amd64-*" }
		postbuildcommands(macosxGmakeBundleCommands(macosxAmd64DependencyDylibs))

	filter {}

	if(_OPTIONS["with-librw"]) then
		dependson "librw"
	end

	files { addSrcFiles("src") }
	files { addSrcFiles("src/animation") }
	files { addSrcFiles("src/audio") }
	files { addSrcFiles("src/audio/eax") }
	files { addSrcFiles("src/audio/oal") }
	files { addSrcFiles("src/buildings") }
	files { addSrcFiles("src/collision") }
	files { addSrcFiles("src/control") }
	files { addSrcFiles("src/core") }
	files { addSrcFiles("src/entities") }
	files { addSrcFiles("src/math") }
	files { addSrcFiles("src/modelinfo") }
	files { addSrcFiles("src/objects") }
	files { addSrcFiles("src/peds") }
	files { addSrcFiles("src/renderer") }
	files { addSrcFiles("src/rw") }
	files { addSrcFiles("src/save") }
	files { addSrcFiles("src/skel") }
	files { addSrcFiles("src/skel/glfw") }
	files { addSrcFiles("src/text") }
	files { addSrcFiles("src/vehicles") }
	files { addSrcFiles("src/weapons") }
	files { addSrcFiles("src/extras") }
	if(not _OPTIONS["no-git-hash"]) then
		files { "src/extras/GitSHA1.cpp" } -- this won't be in repo in first build
	else
		removefiles { "src/extras/GitSHA1.cpp" } -- but it will be everytime after
	end

	includedirs { "src" }
	includedirs { "src/animation" }
	includedirs { "src/audio" }
	includedirs { "src/audio/eax" }
	includedirs { "src/audio/oal" }
	includedirs { "src/buildings" }
	includedirs { "src/collision" }
	includedirs { "src/control" }
	includedirs { "src/core" }
	includedirs { "src/entities" }
	includedirs { "src/math" }
	includedirs { "src/modelinfo" }
	includedirs { "src/objects" }
	includedirs { "src/peds" }
	includedirs { "src/renderer" }
	includedirs { "src/rw" }
	includedirs { "src/save/" }
	includedirs { "src/skel/" }
	includedirs { "src/skel/glfw" }
	includedirs { "src/text" }
	includedirs { "src/vehicles" }
	includedirs { "src/weapons" }
	includedirs { "src/extras" }

	filter "action:xcode4"
		externalincludedirs { "src/audio/eax", "src/fakerw", Librw }

	filter {}

	if(not _OPTIONS["no-git-hash"]) then
		defines { "USE_OUR_VERSIONING" }
	end

	filter "platforms:*oal"
		defines { "AUDIO_OAL" }

	filter {}
	if(os.getenv("GTA_III_RE_DIR")) then
		setpaths(os.getenv("GTA_III_RE_DIR") .. "/", "%(cfg.buildtarget.name)")
	end

	filter "platforms:not win*"
		if(not _OPTIONS["no-git-hash"]) then
			prebuildcommands { '"%{prj.location}/../printHash.sh" "%{prj.location}/../src/extras/GitSHA1.cpp"' }
		end
		
	filter "platforms:*glfw*"
		premake.modules.autoconf.parameters = "-lglfw -lX11"
		autoconfigure {
			-- iterates all configs and runs on them
			["dontWrite"] = function (cfg)
				check_symbol_exists(cfg, "haveX11", "glfwGetX11Display", { "X11/Xlib.h", "X11/XKBlib.h", "GLFW/glfw3.h", "GLFW/glfw3native.h" }, "GLFW_EXPOSE_NATIVE_X11")
				if cfg.autoconf["haveX11"] ~= nil and cfg.autoconf["haveX11"] == 1 then
					table.insert(cfg.links, "X11")
					table.insert(cfg.defines, "GET_KEYBOARD_INPUT_FROM_X11")
				end
			end
		}

	filter "platforms:linux*oal"
		links { "openal", "mpg123", "pthread" }
		
	filter "platforms:bsd*oal"
		links { "openal", "mpg123", "pthread" }

	filter { "platforms:macosx*oal", "action:not xcode4" }
		links { "openal", "mpg123", "pthread" }

	filter "platforms:macosx-arm64-*oal"
		dependencyincludedirs(existingDirectories { "/opt/homebrew/opt/openal-soft/include" })
		libdirs(existingDirectories { "/opt/homebrew/opt/openal-soft/lib" })

	filter "platforms:macosx-amd64-*oal"
		dependencyincludedirs(existingDirectories { "/usr/local/opt/openal-soft/include" })
		libdirs(existingDirectories { "/usr/local/opt/openal-soft/lib" })

	filter "platforms:*librw*"
		defines { "LIBRW" }
		files { addSrcFiles("src/fakerw") }
		includedirs { "src/fakerw" }
		includedirs { Librw }
		if(_OPTIONS["with-librw"] and _ACTION ~= "xcode4") then
			libdirs { "vendor/librw/lib/%{cfg.platform}/%{cfg.buildcfg}" }
		end
		links { "rw" }

	filter "platforms:linux*gl3_glfw*"
		links { "GL", "glfw" }

	filter "platforms:bsd*gl3_glfw*"
		links { "GL", "glfw", "sysinfo" }
		includedirs { "/usr/local/include" }
		libdirs { "/usr/local/lib" }

	filter { "platforms:macosx*gl3_glfw*", "action:not xcode4" }
		links { "glfw" }
		linkoptions { "-framework OpenGL" }

	filter "platforms:macosx-arm64-*gl3_glfw*"
		dependencyincludedirs { "/opt/local/include", "/opt/homebrew/include" }
		libdirs { "/opt/local/lib", "/opt/homebrew/lib" }

	filter "platforms:macosx-amd64-*gl3_glfw*"
		dependencyincludedirs { "/opt/local/include", "/usr/local/include" }
		libdirs { "/opt/local/lib", "/usr/local/lib" }

	filter { "system:macosx", "action:xcode4" }
		links { "OpenGL.framework" }
		dependencyincludedirs(existingDirectories {
			"/opt/local/include",
			"/opt/homebrew/include",
			"/usr/local/include",
			"/opt/homebrew/opt/openal-soft/include",
			"/usr/local/opt/openal-soft/include",
		})
		xcodebuildsettings {
			["LIBRARY_SEARCH_PATHS[arch=arm64]"] = existingXcodeSearchPaths { "/opt/local/lib", "/opt/homebrew/lib", "/opt/homebrew/opt/openal-soft/lib" },
			["LIBRARY_SEARCH_PATHS[arch=x86_64]"] = existingXcodeSearchPaths { "/opt/local/lib", "/usr/local/lib", "/usr/local/opt/openal-soft/lib" },
		}
