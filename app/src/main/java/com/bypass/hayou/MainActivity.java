package com.bypass.hayou;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import java.util.List;

public class MainActivity extends Activity {
    private TextView statusText;
    private Button startBypassBtn;
    private Button stopBypassBtn;
    private BypassManager bypassManager;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        initViews();
        initBypassManager();
        checkTargetApp();
    }
    
    private void initViews() {
        statusText = findViewById(R.id.status_text);
        startBypassBtn = findViewById(R.id.start_bypass_btn);
        stopBypassBtn = findViewById(R.id.stop_bypass_btn);
        
        startBypassBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startBypass();
            }
        });
        
        stopBypassBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                stopBypass();
            }
        });
        
        stopBypassBtn.setEnabled(false);
    }
    
    private void initBypassManager() {
        bypassManager = new BypassManager(this);
    }
    
    private void checkTargetApp() {
        PackageManager pm = getPackageManager();
        List<ApplicationInfo> apps = pm.getInstalledApplications(PackageManager.GET_META_DATA);
        
        boolean found = false;
        for (ApplicationInfo app : apps) {
            if (app.packageName.contains("hayou") || app.packageName.contains("哈友")) {
                found = true;
                updateStatus("检测到目标应用: " + app.packageName);
                break;
            }
        }
        
        if (!found) {
            updateStatus("未检测到哈友工具箱，请先安装目标应用");
        }
    }
    
    private void startBypass() {
        updateStatus("正在启动绕过服务...");
        
        if (bypassManager.startBypass()) {
            updateStatus("绕过服务已启动，正在Hook目标应用...");
            startBypassBtn.setEnabled(false);
            stopBypassBtn.setEnabled(true);
            
            // 启动后台服务
            Intent serviceIntent = new Intent(this, BypassService.class);
            startService(serviceIntent);
            
            Toast.makeText(this, "绕过已激活", Toast.LENGTH_SHORT).show();
        } else {
            updateStatus("绕过服务启动失败，请检查Root权限");
            Toast.makeText(this, "启动失败，需要Root权限", Toast.LENGTH_LONG).show();
        }
    }
    
    private void stopBypass() {
        updateStatus("正在停止绕过服务...");
        
        if (bypassManager.stopBypass()) {
            updateStatus("绕过服务已停止");
            startBypassBtn.setEnabled(true);
            stopBypassBtn.setEnabled(false);
            
            // 停止后台服务
            Intent serviceIntent = new Intent(this, BypassService.class);
            stopService(serviceIntent);
            
            Toast.makeText(this, "绕过已停止", Toast.LENGTH_SHORT).show();
        } else {
            updateStatus("绕过服务停止失败");
        }
    }
    
    private void updateStatus(String status) {
        statusText.setText(status);
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (bypassManager != null) {
            bypassManager.cleanup();
        }
    }
}