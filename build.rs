fn main() {
    let target = std::env::var("TARGET").unwrap();
    let out_dir = std::env::var("OUT_DIR").unwrap();
    
    // 根据目标操作系统确定动态库文件名
    let file_name = if cfg!(target_os = "windows") {
        "linguaspark.dll"
    } else if cfg!(target_os = "macos") {
        "liblinguaspark.dylib"
    } else {
        "liblinguaspark.so"
    };

    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let dynlib_path = format!("{}/linguaspark/build/", manifest_dir);

    // 优先检查本地是否已存在动态库
    if std::path::PathBuf::from(&dynlib_path)
        .join(file_name)
        .exists()
    {
        println!("cargo:rustc-link-search={}", dynlib_path);
    } else {
        // 如果本地不存在，则根据目标平台下载对应的预编译库
        let archive_name = if cfg!(target_os = "linux") {
            if cfg!(target_arch = "x86_64") {
                "linguaspark-x86_64-linux.tar.gz"
            } else if cfg!(target_arch = "aarch64") {
                "linguaspark-aarch64-linux.tar.gz" // 新增: ARM64 Linux
            } else {
                panic!("Unsupported Linux architecture. Please build the dynamic library for your architecture.")
            }
        } else if cfg!(target_os = "macos") {
            if cfg!(target_arch = "x86_64") {
                "linguaspark-x86_64-macos.tar.gz" // 新增: Intel macOS
            } else if cfg!(target_arch = "aarch64") {
                "linguaspark-aarch64-macos.tar.gz" // 新增: Apple Silicon (ARM64)
            } else {
                panic!("Unsupported macOS architecture. Please build the dynamic library for your architecture.")
            }
        } else if cfg!(target_os = "windows") {
            if cfg!(target_arch = "x86_64") {
                "linguaspark-x86_64-windows.tar.gz" // 新增: Windows (为了完整性)
            } else {
                panic!("Unsupported Windows architecture. Please build the dynamic library for your architecture.")
            }
        } else {
            panic!("Unsupported target OS. Please build the dynamic library for your OS.")
        };

        let url =
            format!("https://github.com/LinguaSpark/core/releases/download/latest/{archive_name}");

        println!("cargo:warning=Downloading {}", url);
        let resp = minreq::get(url).send().unwrap();
        if resp.status_code != 200 {
            panic!("Download failed: {}", resp.status_code);
        }

        let archive_path = std::path::PathBuf::from(&out_dir).join(archive_name);
        std::fs::write(&archive_path, resp.as_bytes()).unwrap();

        println!("cargo:warning=Unpacking {}", archive_path.display());
        let status = std::process::Command::new("tar")
            .arg("xzf")
            .arg(&archive_path)
            .current_dir(&out_dir)
            .status()
            .expect("Failed to execute tar command");

        if !status.success() {
            panic!("Failed to unpack the archive");
        }

        std::fs::remove_file(archive_path).unwrap_or_else(|e| {
            println!("cargo:warning=Failed to remove archive file: {}", e);
        });

        // 修改: 使用已定义的 file_name 变量，而不是硬编码
        let extracted_lib_path = std::path::PathBuf::from(&out_dir).join(file_name);
        if !extracted_lib_path.exists() {
            panic!(
                "Failed to find the extracted library file at {:?}",
                extracted_lib_path
            );
        }

        println!("cargo:rustc-link-search={}", out_dir);
    }

    // 设置 RPATH，以便运行时能找到动态库
    if !target.contains("windows") {
        let rpath_arg = if target.contains("apple") {
            "-Wl,-rpath,@loader_path"
        } else {
            "-Wl,-rpath,$ORIGIN"
        };
        println!("cargo:rustc-link-arg={}", rpath_arg);
    }
    
    println!("cargo:rustc-link-lib=linguaspark");
    println!("cargo:rerun-if-changed=build.rs");
}
