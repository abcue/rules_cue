// This file tests whether imports with colons can be resolved
package colon_imports

import "github.com/abcue/tool"

// Reference the imported types
regularImport: tool.RunPrint
colonImport:   tool.RunPrint
