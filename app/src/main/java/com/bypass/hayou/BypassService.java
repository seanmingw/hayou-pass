package com.bypass.hayou;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.util.Log;
import android.app.PendingIntent;
import androidx.core.app.NotificationCompat;

public class BypassService extends Service {
    private static final String TAG = "BypassService";
    private static final int NOTIFICATION_ID = 1001;
    private static final String CHANNEL_ID = "bypass_channel";
    
    private BypassManager bypassManager;
    private Thread monitorThread;
    private boolean isRunning = false;
    
    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "BypassService创建");
        
        bypassManager = new BypassManager(this);
        createNotificationChannel();
    }
    
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "BypassService启动");
        
        startForeground(NOTIFICATION_ID, createNotification());
        
        if (!isRunning) {
            startMonitoring();
        }
        
        return START_STICKY; // 服务被杀死后自动重启
    }
    
    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "BypassService销毁");
        
        isRunning = false;
        if (monitorThread != null) {
            monitorThread.interrupt();
        }
        
        if (bypassManager != null) {
            bypassManager.cleanup();
        }
    }
    
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
    
    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "绕过服务",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("哈友工具箱绕过服务正在运行");
            
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(channel);
        }
    }
    
    private Notification createNotification() {
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, 
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ? 
                PendingIntent.FLAG_IMMUTABLE : 0
        );
        
        return new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("哈友工具箱绕过")
            .setContentText("绕过服务正在运行中...")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build();
    }
    
    private void startMonitoring() {
        isRunning = true;
        
        monitorThread = new Thread(new Runnable() {
            @Override
            public void run() {
                Log.d(TAG, "开始监控目标应用");
                
                while (isRunning && !Thread.currentThread().isInterrupted()) {
                    try {
                        // 检查目标应用是否运行
                        if (isTargetAppRunning()) {
                            if (!bypassManager.isActive()) {
                                Log.d(TAG, "检测到目标应用，启动绕过");
                                bypassManager.startBypass();
                            }
                        }
                        
                        // 每5秒检查一次
                        Thread.sleep(5000);
                        
                    } catch (InterruptedException e) {
                        Log.d(TAG, "监控线程被中断");
                        break;
                    } catch (Exception e) {
                        Log.e(TAG, "监控过程中出错: " + e.getMessage());
                    }
                }
                
                Log.d(TAG, "监控线程结束");
            }
        });
        
        monitorThread.start();
    }
    
    private boolean isTargetAppRunning() {
        try {
            android.app.ActivityManager am = (android.app.ActivityManager) 
                getSystemService(ACTIVITY_SERVICE);
            
            java.util.List<android.app.ActivityManager.RunningAppProcessInfo> processes = 
                am.getRunningAppProcesses();
            
            if (processes != null) {
                for (android.app.ActivityManager.RunningAppProcessInfo process : processes) {
                    if (process.processName.contains("hayou") || 
                        process.processName.contains("哈友")) {
                        return true;
                    }
                }
            }
            
        } catch (Exception e) {
            Log.e(TAG, "检查目标应用运行状态失败: " + e.getMessage());
        }
        
        return false;
    }
}