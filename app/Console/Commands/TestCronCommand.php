<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class TestCronCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'cron:test';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Test cron functionality by logging timestamps';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $logFile = storage_path('logs/cron-test.log');
        $timestamp = now()->format('Y-m-d H:i:s');
        $message = "Cron executed at: {$timestamp}\n";
        
        file_put_contents($logFile, $message, FILE_APPEND);
        
        $this->info("Cron test logged at {$timestamp}");
        
        return 0;
    }
}
