class Marketstore < Formula
  desc "DataFrame Server for Financial Timeseries Data"
  homepage "https://github.com/alpacahq/marketstore"
  head "https://github.com/alpacahq/marketstore.git"

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    marketstore_path = buildpath/"src/github.com/alpacahq/marketstore"
    marketstore_path.install Dir["*"]

    cd marketstore_path do
      system "make", "vendor"
      system "make", "install"
      system "make", "plugins"
    end

    binaries = [
      "marketstore",
      "binancefeeder.so",
      "bitmexfeeder.so",
      "gdaxfeeder.so",
      "iex.so",
      "ondiskagg.so",
      "polygon.so",
      "slait.so",
      "stream.so",
      "xignitefeeder.so"
    ]

    binaries.each { |b| bin.install "bin/#{b}" }

    (prefix/"data").mkpath  # for storing WAL file
  end

  def post_install
    cd prefix do
      system "marketstore", "init"  # for generating mkts.yml
    end
  end

  plist_options :manual => "marketstore start"

  def caveats
    <<~EOS
      Before you manually start marketstore, you must do the following prerequisites
      1. configuration file `mkts.yml` need to be created by running:
        marketstore init
      2. create the directory for storing database file which indicated by the `root_directory`
      attribute in the `mkts.yml` configuration file you just created
    EOS
  end

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>KeepAlive</key>
        <dict>
          <key>SuccessfulExit</key>
          <false/>
        </dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{bin}/marketstore</string>
          <string>start</string>
          <string>--config</string>
          <string>#{prefix}/mkts.yml</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{prefix}</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/marketstore.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/marketstore.log</string>
        <key>SoftResourceLimits</key>
        <dict>
          <key>NumberOfFiles</key>
          <integer>10240</integer>
        </dict>
      </dict>
    </plist>
  EOS
  end

  test do
    system "marketstore", "estimate"
  end
end
