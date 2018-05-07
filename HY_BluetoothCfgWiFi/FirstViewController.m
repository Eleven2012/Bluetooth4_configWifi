//
//  FirstViewController.m
//  HY_BluetoothCfgWiFi
//
//  Created by 孔雨露 on 2018/5/4.
//  Copyright © 2018年 孔雨露. All rights reserved.
//

#import "FirstViewController.h"

#import "BTDataType.h"
#import "LGBluetooth.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "EasyUtils.h"
#import "EFShowView.h"

static NSString * SERVICEID = @"1803";
static NSString * CHARACTERISTICID = @"2A06";

static const int BUF_SIZE = 600;

typedef NS_ENUM(NSInteger, YH_RequestType) {
    
    YH_RequestType_GetWiFiList = 0,    //获取摄像机WiFi列表
    YH_RequestType_SetWiFi = 1,    //设置摄像机WiFi
    YH_RequestType_GetWiFiParam = 2,    //获取摄像机当前设置的WiFi信息
    YH_RequestType_Reset = 3    //重置摄像机
};

@interface FirstViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    int count;
}
@property (weak, nonatomic) IBOutlet UILabel *ssidLable;
@property (weak, nonatomic) IBOutlet UILabel *labelPassword;
@property (weak, nonatomic) IBOutlet UILabel *labelDID;
@property (weak, nonatomic) IBOutlet UITextField *textFieldSSID;
@property (weak, nonatomic) IBOutlet UITextField *textFieldPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldDID;
@property (weak, nonatomic) IBOutlet UIButton *btnWiFiList;
@property (weak, nonatomic) IBOutlet UIButton *btnWiFiConf;
@property (weak, nonatomic) IBOutlet UIButton *btnGetWiFi;
@property (weak, nonatomic) IBOutlet UIButton *btnReset;
@property (weak, nonatomic) IBOutlet UIButton *btnSearch;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *lableConnectDescribe;

@property (nonatomic, copy) NSString *cameraDid;
@property (nonatomic, copy) NSString *wifiSsid;
@property (nonatomic, copy) NSString *wifPassword;

@property (strong,nonatomic ) NSMutableArray          *nDevices;
@property (nonatomic, assign) int  bReqRecv;
@property (nonatomic, assign) int  nDataSize;
@property (nonatomic, assign) char *pDataBuf;

@property (nonatomic, strong) LGPeripheral *selectPeripheral;
@property (nonatomic, strong) LGService *selectService;
@property (nonatomic, strong) LGCharacteristic *selectCharacteristic;
@end

@implementation FirstViewController

-(void) dealloc{
    if(_pDataBuf){
        free(_pDataBuf);
        _pDataBuf = NULL;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Initialization of CentralManager
    //初始化数据
    self.bReqRecv = 0;
    self.nDataSize = 0;
    _pDataBuf = malloc(BUF_SIZE);
    memset(_pDataBuf, 0, BUF_SIZE);
    _nDevices = [[NSMutableArray alloc] initWithCapacity:10];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [LGCentralManager sharedInstance];
    // Do any additional setup after loading the view, typically from a nib.
    self.cameraDid = @"VIEW-747390-SGLEV";
    self.wifiSsid = [self fetchSSIDInfo];
    self.wifPassword = @"790511kyl";
    self.wifiSsid = [self fetchSSIDInfo];
    [self updateUI];
}


-(void) updateUI{
    self.textFieldDID.text = self.cameraDid;
    self.textFieldSSID.text = self.wifiSsid;
    self.textFieldPassword.text = self.wifPassword;
}

-(void) getUIInput{
    self.cameraDid = self.textFieldDID.text;
    self.wifiSsid = self.textFieldSSID.text;
    self.wifPassword = self.textFieldPassword.text;
}

-(NSString *)fetchSSIDInfo
{
    NSString *currentSSID = @"Not Found";
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil){
        NSDictionary* myDict = (__bridge NSDictionary *) CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict!=nil){
            currentSSID=[myDict valueForKey:@"SSID"];
            
        } else {
            currentSSID=@"<<NONE>>";
        }
    } else {
        currentSSID=@"<<NONE>>";
    }
    CFRelease(myArray);
    return currentSSID;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void) initCameras{
    [self.nDevices removeAllObjects];
    self.selectCharacteristic = nil;
    self.selectService = nil;
    self.selectPeripheral = nil;
}

- (IBAction)btnSearchClicked:(id)sender {
    
    [self initCameras];
     [self.tableView reloadData];
    [self updateLog:@"正在搜索设备..."];
    [EFShowView showHUDMsg:@"正在搜索..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [EFShowView HideHud];
    });
    [[LGCentralManager sharedInstance] scanForPeripheralsByInterval:4
                                                         completion:^(NSArray *peripherals)
     {
         [EFShowView HideHud];
         kWeakSelf(self)
         // If we found any peripherals sending to test
         if (peripherals.count) {
             //[self testPeripheral:peripherals[0]];
             //判断是否存在我们对应的设备
             for (int i=0; i<[peripherals count]; i++) {
                 LGPeripheral *peripheral = peripherals[i];
                 NSLog(@"扫描到设备：uuid=%@,name=%@",peripheral.UUIDString,peripheral.name);
                 if([peripheral.name hasPrefix:@"HY"]){
                     [weakself.nDevices addObject:peripheral];
                     queueMainStart
                     NSString *strMsg =[NSString stringWithFormat: @"扫描到设备慧眼设备：%@",peripheral.name ];
                     [weakself updateLog:strMsg];
                     [weakself.tableView reloadData];
                     queueEnd
                 }
             }
         }
     }];
}

- (IBAction)btnWiFiListClicked:(id)sender {
     [self getUIInput];
    if([self.nDevices count]>0)
    {
        if ([self isChooseDevice]) {
            if(self.selectService && self.selectCharacteristic)
            {
                [self getCameraWiFiList:self.selectCharacteristic];
            }
        }
    }
    else{
        [self sendCmdToCamera:YH_RequestType_GetWiFiList];
    }
    
    
}
- (IBAction)btnWiFiConfClicked:(id)sender {
     [self getUIInput];
    if([self.nDevices count]>0)
    {
        if ([self isChooseDevice]) {
            if(self.selectService && self.selectCharacteristic)
            {
                [self setCameraWiFi:self.selectCharacteristic];
            }
        }
    }
    else{
        [self sendCmdToCamera:YH_RequestType_SetWiFi];
    }

}
- (IBAction)btnGetWiFiClicked:(id)sender {
     [self getUIInput];
    if([self.nDevices count]>0)
    {
        if ([self isChooseDevice]) {
            if(self.selectService && self.selectCharacteristic)
            {
                [self getCameraWiFiInfo:self.selectCharacteristic];
            }
        }
    }
    else{
        [self sendCmdToCamera:YH_RequestType_GetWiFiParam];
    }

}
- (IBAction)btnResetClicked:(id)sender {
     [self getUIInput];
    if([self.nDevices count]>0)
    {
        if ([self isChooseDevice]) {
            if(self.selectService && self.selectCharacteristic)
            {
                [self resetCamera:self.selectCharacteristic];
            }
        }
    }
    else{
        [self sendCmdToCamera:YH_RequestType_Reset];
    }
}

-(void) getCameraWiFiList:(LGCharacteristic *) charact{
    if(nil == charact) {
        NSString *strMsg = [NSString stringWithFormat:@"getCameraWiFiList 错误，charact 为空"];
        [self updateLog:strMsg];
    }
    REQ_WIFI_LIST stReq;
    memset(&stReq, 0, sizeof(stReq));
    stReq.nHeaderFlag = BTDATA_HEADER_FLAG;
    stReq.nOperType = WIFI_LIST_REQ;
    NSData * msgData = [[NSData alloc]initWithBytes:&stReq length:sizeof(REQ_WIFI_LIST)];
    NSString *strPeripheralName = self.selectPeripheral.name;
    NSString *strMsg = [NSString stringWithFormat:@"向设备:%@写入数据 特征ID:%@，发送获取摄像机WiFi列表请求数据 datalen=%ld",strPeripheralName,CHARACTERISTICID,[msgData length] ];
    [self updateLog:strMsg];
    [EFShowView showHUDMsg:@"正在发送获取WiFi列表请求"];
    
    memset(self.pDataBuf, 0, sizeof(BUF_SIZE));
    self.nDataSize=0;
    self.bReqRecv=0;
    kWeakSelf(self)
    [charact writeValue:msgData completion:^(NSData *data,NSError *error) {
        // finnally disconnecting
        NSLog(@"成功写入数据(REQ_WIFI_LIST)到1803,2A06,error=%@",error);
        [EFShowView HideHud];
        const char *pDataOnce=[data bytes];
        for(int i=0; i<[data length]; i++){
            printf("0x%02X ", pDataOnce[i]&0xFF);
            if((i!=0) && ((i+1)%8)==0) printf("   ");
        }
        printf("\n");
        weakself.bReqRecv=1;
        NSString *strMsg = [NSString stringWithFormat:@"向设备:%@写入数据 特征ID:%@，发送获取摄像机WiFi列表,请求完成，，回调响应respdatalen=%ld",strPeripheralName,CHARACTERISTICID,[data length] ];
        [weakself updateLog:strMsg];
    }];//end for block writeValue
    //开始读取数据
    [self readGetWiFiListResp:charact];
}

-(void) setCameraWiFi:(LGCharacteristic *) charact{
    if([self.wifiSsid length] < 1 )
    {
        NSString *strMsg =[NSString stringWithFormat: @"请输入正确的WiFi SSID和密码"];
        [EFShowView showText:strMsg];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EFShowView HideHud];
        });
        return;
    }
    if(nil == charact) {
        NSString *strMsg = [NSString stringWithFormat:@"setCameraWiFi 错误，charact 为空"];
        [self updateLog:strMsg];
        return;
    }
    REQ_SET_WIFI_PARAM stReq;
    memset(&stReq, 0, sizeof(stReq));
    stReq.nHeaderFlag = BTDATA_HEADER_FLAG;
    stReq.nOperType = SETWIFI_PARAM_REQ;
    strcpy(stReq.chSSID,[self.wifiSsid UTF8String]);
    strcpy(stReq.chKey,[self.wifPassword UTF8String]);
    stReq.eWiFiSecurityMode = E_WIFI_SECURITY_MODE_UNKNOW;
    NSData * msgData = [[NSData alloc]initWithBytes:&stReq length:sizeof(REQ_SET_WIFI_PARAM)];
    NSString *strPeripheralName = self.selectPeripheral.name;
    NSString *strMsg = [NSString stringWithFormat:@"向设备:%@写入数据 特征ID:%@，发送设置摄像机WiFi,请求数据 datalen=%ld",strPeripheralName,CHARACTERISTICID,[msgData length] ];
    [self updateLog:strMsg];
    
    [EFShowView showHUDMsg:@"正在发送设置摄像机WiFi请求"];
    //大于20个字节
    [self sendSetWiFiInfoCmd:charact data:msgData];
    
    //发送完成之后，等待几秒钟，在主动读取设置结果
    [self getSetWiFiResp:charact];
}

-(void) getCameraWiFiInfo:(LGCharacteristic *) charact{
    if(nil == charact) {
        NSString *strMsg = [NSString stringWithFormat:@"getCameraWiFiInfo 错误，charact 为空"];
        [self updateLog:strMsg];
        return;
    }
    
    REQ_GET_WIFI_PARAM stReq;
    memset(&stReq, 0, sizeof(stReq));
    stReq.nHeaderFlag = BTDATA_HEADER_FLAG;
    stReq.nOperType = GETWIFI_PARAM_REQ;
    NSData * msgData = [[NSData alloc]initWithBytes:&stReq length:sizeof(REQ_GET_WIFI_PARAM)];
    NSString *strPeripheralName = self.selectPeripheral.name;
    NSString *strMsg = [NSString stringWithFormat:@"向设备:%@写入数据 特征ID:%@，发送获取摄像机当前设置的WiFi信息,请求数据 datalen=%ld",strPeripheralName,CHARACTERISTICID,[msgData length] ];
    [self updateLog:strMsg];
    [EFShowView showHUDMsg:@"正在发送获取摄像机WiFi请求"];

    memset(self.pDataBuf, 0, sizeof(BUF_SIZE));
    self.nDataSize=0;
    self.bReqRecv=0;
    
    kWeakSelf(self)
    [charact writeValue:msgData completion:^(NSData *data,NSError *error) {
        // finnally disconnecting
        NSLog(@"成功写入数据(REQ_GET_WIFI_PARAM)到1803,2A06,error=%@",error);
        NSString *strMsg = @"成功写入数据，正在等待读取数据...";
        [EFShowView showHUDMsg:strMsg];
        [weakself updateLog:strMsg];
        const char *pDataOnce=[data bytes];
        for(int i=0; i<[data length]; i++){
            printf("0x%02X ", pDataOnce[i]&0xFF);
            if((i!=0) && ((i+1)%8)==0) printf("   ");
        }
        printf("\n");
        weakself.bReqRecv=1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EFShowView HideHud];
        });
        //[peripheral disconnectWithCompletion:nil];
        
    }];//end for block writeValue
    //读取结果
    [self readGetCameraWiFiInfoResp:charact];
}


-(void) resetCamera:(LGCharacteristic *) charact{
    if(nil == charact) {
        NSString *strMsg = [NSString stringWithFormat:@"resetCamera 错误，charact 为空"];
        [self updateLog:strMsg];
        return;
    }
    REQ_RESET_IPC stReq;
    memset(&stReq, 0, sizeof(stReq));
    stReq.nHeaderFlag = BTDATA_HEADER_FLAG;
    stReq.nOperType = RESET_IPC_REQ;
    NSData * msgData = [[NSData alloc]initWithBytes:&stReq length:sizeof(REQ_RESET_IPC)];
    NSString *strPeripheralName = self.selectPeripheral.name;
    NSString *strMsg = [NSString stringWithFormat:@"向设备:%@写入数据 特征ID:%@，发送重置摄像机,请求数据 datalen=%ld",strPeripheralName,CHARACTERISTICID,[msgData length] ];
    [self updateLog:strMsg];
    [EFShowView showHUDMsg:@"正在发送重置摄像机请求"];

    kWeakSelf(self)
    [charact writeValue:msgData completion:^(NSData *data,NSError *error) {
        // finnally disconnecting
        NSLog(@"成功写入数据(REQ_RESET_IPC)到1803,2A06,error=%@",error);
        
        [EFShowView HideHud];
        //得到结构体
        RES_RESET_IPC stResp;
        memset(&stResp, 0, sizeof(stResp));
        [data getBytes:&stResp length:sizeof(stResp)];
        
        NSString *strMsg = [NSString stringWithFormat:@"向设备:%@写入数据 特征ID:%@，发送重置摄像机,请求完成，，回调响应respdatalen=%ld,RES_RESET_IPC ret=%d,nHeaderFlag=%d,nOperType=%d",strPeripheralName,CHARACTERISTICID,[data length],stResp.nRetCode ,stResp.nHeaderFlag,stResp.nHeaderFlag];
        [weakself updateLog:strMsg];
        
        //[peripheral disconnectWithCompletion:nil];
        
    }];//end for block writeValue
}

-(BOOL) isChooseDevice{
    if (self.selectPeripheral == nil) {
        NSString *strMsg =[NSString stringWithFormat: @"请先选中扫描到的慧眼设备"];
        [EFShowView showText:strMsg];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EFShowView HideHud];
        });
        return NO;
    }
    return YES;
}

-(NSString *)getCmdDescribe:(int) type{
    NSString *strDescribe = nil;
    switch (type) {
        case YH_RequestType_GetWiFiList://获取摄像机WiFi列表
        {
            strDescribe = @"获取摄像机WiFi列表...";
        }
            break;
        case YH_RequestType_SetWiFi://设置摄像机WiFi
        {
            strDescribe = @"设置摄像机WiFi...";
        }
            break;
        case YH_RequestType_GetWiFiParam://获取摄像机当前设置的WiFi信息
        {
            strDescribe = @"获取摄像机WiFi信息...";
        }
            break;
        case YH_RequestType_Reset://重置摄像机
        {
            strDescribe = @"重置摄像机...";
        }
            break;
            
        default:
            break;
    }
    return strDescribe;
}

//textView更新
-(void)updateLog:(NSString *)s
{
    [self.logTextView setText:[NSString stringWithFormat:@"[ %d ]  %@\r\n%@",count,s,_logTextView.text]];
    count++;
}

- (LGService *)getService:(LGPeripheral *)per serviceUUID:(NSString *) serviceUUID
{
    if(per == nil || serviceUUID == nil) return nil;
    LGService *wrapper = nil;
    for (LGService *discovered in per.services) {
        if ([serviceUUID compare:discovered.UUIDString options:NSCaseInsensitiveSearch|NSNumericSearch] == NSOrderedSame) {
            break;
        }
    }
    return wrapper;
}

- (LGCharacteristic *)getCharact:(LGService *)service charactUUID:(NSString *) charactUUID
{
    if (service == nil || charactUUID == nil) {
        return nil;
    }
    LGCharacteristic *charact = nil;
    for (int i=0; i < [service.characteristics count]; i++) {
        charact = [service.characteristics objectAtIndex:i];
        if ([charactUUID compare:charact.UUIDString options:NSCaseInsensitiveSearch|NSNumericSearch] == NSOrderedSame) {
            return charact;
        }
    }
    return charact;
}

-(void) findService:(LGPeripheral *)per{
    kWeakSelf(self)
    {
        NSString *strMsg = [NSString stringWithFormat:@"连接设备:%@",per.name];
        [EFShowView showHUDMsg:strMsg];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EFShowView HideHud];
        });
        //找到慧眼摄像机，开始连线设备
        strMsg = [NSString stringWithFormat:@"查找设备:%@的服务",per.name];
        [weakself updateLog:strMsg];
        // First of all connecting to peripheral
        [per connectWithCompletion:^(NSError *error) {
            
            NSString *strMsg = [NSString stringWithFormat:@"连接设备:%@，error=%@",per.name,error];
            [weakself updateLog:strMsg];
            strMsg = [NSString stringWithFormat:@"%@已经连接",per.name];
            self.lableConnectDescribe.text = strMsg;
            // Discovering services of peripheral
            [per discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
                
                NSString *strMsg = [NSString stringWithFormat:@"扫描设备:%@的服务，error=%@",per.name,error];
                [weakself updateLog:strMsg];
                [EFShowView showHUDMsg:strMsg];
                
                for (LGService *service in services) {
                    // Finding out our service
                    if([service.UUIDString compare:SERVICEID options:NSCaseInsensitiveSearch|NSNumericSearch] == NSOrderedSame) {
                        
                        NSString *strMsg = [NSString stringWithFormat:@"找到设备:%@的服务ID:%@，error=%@",per.name,SERVICEID,error];
                        [weakself updateLog:strMsg];
                        weakself.selectService = service;
                        // Discovering characteristics of our service
                        [service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
                            // We need to count down completed operations for disconnecting
                            NSString *strMsg = [NSString stringWithFormat:@"扫描设备:%@的特征，error=%@,count=%ld",per.name,error,[characteristics count]];
                            [weakself updateLog:strMsg];
                            for (LGCharacteristic *charact in characteristics) {
                                if([charact.UUIDString compare:CHARACTERISTICID options:NSCaseInsensitiveSearch|NSNumericSearch] == NSOrderedSame)
                                {
                                    
                                    NSString *strMsg = [NSString stringWithFormat:@"找到设备:%@的特征ID:%@，error=%@",per.name,CHARACTERISTICID,error];
                                    [weakself updateLog:strMsg];
                                    [EFShowView showHUDMsg:strMsg];
                                    
                                    weakself.selectCharacteristic = charact;
                                    strMsg = [NSString stringWithFormat:@"%@已经连接，找到了服务：%@,特征：%@",per.name,SERVICEID,CHARACTERISTICID];
                                    self.lableConnectDescribe.text = strMsg;
                                }
                            }
                        }];//end for block discoverCharacteristicsWithCompletion
                    }// end for if ([service.UUIDString isEqualToString:SERVICEID])
                } // end for for (LGService *service in services)
            }];// end for block [peripheral connectWithCompletion:^(NSError *error)
        }]; // end for block [peripheral connectWithCompletion:^(NSError *error)
    }
}

-(void) sendCmdToCamera:(YH_RequestType) type{
    
    NSString *strMsg = [self getCmdDescribe:type];
    [EFShowView showHUDMsg:strMsg];

    /* 1. 先扫描获取到HY开头的摄像机
       2. 连接摄像机
       3. 扫描摄像机的服务，查找服务号1803
       4. 获取1803服务的特征 ，可读可写的特征2A06
       5. 向特征2A06, 写数据,发送请求
       6. 从特征读取数据
     */
    __weak typeof(self) weakSelf = self;
    //queueGlobalStart
    
    [[LGCentralManager sharedInstance] scanForPeripheralsByInterval:4
                                                         completion:^(NSArray *peripherals)
     {
         NSString *strMsg = @"扫描到设备";
         [weakSelf updateLog:strMsg];
         [EFShowView showHUDMsg:strMsg];
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             [EFShowView HideHud];
         });
         [weakSelf.tableView reloadData];
         
         //判断是否存在我们对应的设备
         for (int i=0; i<[peripherals count]; i++) {
             LGPeripheral *peripheral = peripherals[i];
             NSString *strPeripheralName = peripheral.name;
             NSLog(@"扫描到设备：uuid=%@,name=%@",peripheral.UUIDString,strPeripheralName);
             if([strPeripheralName hasPrefix:@"HY"]){
                 //找到慧眼摄像机，开始连线设备
                 
                 NSString *strMsg = [NSString stringWithFormat:@"找到慧眼设备:%@",strPeripheralName];
                 [weakSelf updateLog:strMsg];
                 
                 
                 // First of all connecting to peripheral
                 [peripheral connectWithCompletion:^(NSError *error) {
                     
                     NSString *strMsg = [NSString stringWithFormat:@"连接设备:%@，error=%@",strPeripheralName,error];
                     [weakSelf updateLog:strMsg];
                     
                     
                     // Discovering services of peripheral
                     [peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
                         
                         NSString *strMsg = [NSString stringWithFormat:@"扫描设备:%@的服务，error=%@",strPeripheralName,error];
                         [weakSelf updateLog:strMsg];
                         [EFShowView showHUDMsg:strMsg];
                         
                         for (LGService *service in services) {
                             // Finding out our service
                             if ([service.UUIDString isEqualToString:SERVICEID]) {
                                 
                                 NSString *strMsg = [NSString stringWithFormat:@"找到设备:%@的服务ID:%@，error=%@",strPeripheralName,SERVICEID,error];
                                 [weakSelf updateLog:strMsg];
                                 
                                 
                                 // Discovering characteristics of our service
                                 [service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
                                     // We need to count down completed operations for disconnecting
                                     
                                     NSString *strMsg = [NSString stringWithFormat:@"扫描设备:%@的特征，error=%@,count=%ld",strPeripheralName,error,[characteristics count]];
                                     [weakSelf updateLog:strMsg];
                                     
                                     
                                     __block int i = 0;
                                     for (LGCharacteristic *charact in characteristics)
                                     {
                                         NSString *uuid = charact.UUIDString;
                                         NSLog(@"遍历服务：%@的特征值：%@,要查找的特征：%@",SERVICEID,uuid,CHARACTERISTICID);
                                         // 找到可以读写的特征值
                                         if([uuid compare:CHARACTERISTICID options:NSCaseInsensitiveSearch|NSNumericSearch] == NSOrderedSame)
                                         //if ([uuid isEqualToString:CHARACTERISTICID])
                                         {
                                             
                                             NSString *strMsg = [NSString stringWithFormat:@"找到设备:%@的特征ID:%@，error=%@",strPeripheralName,CHARACTERISTICID,error];
                                             [weakSelf updateLog:strMsg];
                                             [EFShowView showHUDMsg:strMsg];
                                             //[EFShowView HideHud];
                                             switch (type) {
                                                 case YH_RequestType_GetWiFiList://获取摄像机WiFi列表
                                                {
                                                    [weakSelf getCameraWiFiList:charact];
                                                }
                                                     break;
                                                 case YH_RequestType_SetWiFi://设置摄像机WiFi
                                                 {
                                                     [weakSelf setCameraWiFi:charact];
                                                 }
                                                     break;
                                                 case YH_RequestType_GetWiFiParam://获取摄像机当前设置的WiFi信息
                                                 {
                                                     [weakSelf getCameraWiFiInfo:charact];
                                                 }
                                                     break;
                                                 case YH_RequestType_Reset://重置摄像机
                                                 {
                                                     [weakSelf resetCamera:charact];
                                                 }
                                                     break;
                                                     
                                                 default:
                                                     break;
                                             }
                                             
                                             
                                         }//end if
                                     }//end for
                                 }];//end for block discoverCharacteristicsWithCompletion
                             }// end for if ([service.UUIDString isEqualToString:SERVICEID])
                         } // end for for (LGService *service in services)
                     }];// end for block [peripheral connectWithCompletion:^(NSError *error)
                 }]; // end for block [peripheral connectWithCompletion:^(NSError *error)
                 break;
             } // end for if([peripheral.UUIDString hasPrefix:@"HY"])
         }// end for for (int i=0; i<[peripherals count]; i++)
     }];
    //queueEnd
}

-(BOOL) readGetCameraWiFiInfoResp:(LGCharacteristic *) characteristic{
    
    if(characteristic == nil) return NO;
    [EFShowView showHUDMsg:@"正在读取WiFi列表信息..."];
    kWeakSelf(self)
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_queue_create("com.dispatch.kyl", DISPATCH_QUEUE_CONCURRENT), ^{//设置一个异步线程组
        //接收服务1084的通知
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        int i=0, kk=0;
        static int bOK=0;
        for(i=0;i<100;i++){
            if(bOK) break;
            for(kk=0; kk<30; kk++){
                if(!weakself.bReqRecv) {
                    usleep(100000);
                    continue;
                }else break;
            }
            NSLog(@"3s_timeout, g_bReqRecv=%d", weakself.bReqRecv);
            [characteristic readValueWithBlock:^(NSData *data, NSError *error) {
                {
                    NSLog(@"读取数据：%@,len=%d",data, (int)[data length]);
                    const char *pDataOnce=[data bytes];
                    for(int i=0; i<[data length]; i++){
                        printf("0x%02X ", pDataOnce[i]&0xFF);
                        if((i!=0) && ((i+1)%8)==0) printf("   ");
                    }
                    printf("\n");
                    
                    if([data length]>1){
                        memcpy(weakself.pDataBuf+weakself.nDataSize, pDataOnce, (int)[data length]);
                        weakself.nDataSize+=(int)[data length];
                        printf("g_nDataSize=%d\n", weakself.nDataSize);
                    }
                    dispatch_semaphore_signal(sema);
                    
                    if(weakself.nDataSize >= sizeof(RES_GET_WIFI_PARAM)){
                        bOK=1;
                        //得到结构体
                        RES_GET_WIFI_PARAM stResp;
                        memset(&stResp, 0, sizeof(RES_GET_WIFI_PARAM));
                        memcpy(&stResp, weakself.pDataBuf, sizeof(RES_GET_WIFI_PARAM));
                        
                        queueMainStart
                        NSString *strMsg= [NSString stringWithFormat:@"成功读取数据,datalen=%d",weakself.nDataSize];
                        [weakself updateLog:strMsg];
                        [EFShowView HideHud];

                        strMsg = [NSString stringWithFormat:@"解析数据 nRetCode=%d,chSSID=%s,chKey=%s,eWiFiSecurityMode=%d,nWifiStatus=%d,chReserve2=%s",stResp.nRetCode,stResp.chSSID,stResp.chKey,stResp.eWiFiSecurityMode,stResp.nWifiStatus,stResp.chReserve2];
                        [weakself updateLog:strMsg];
                        
                        queueEnd
                        
                    }
                }
            }];
            
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
    });
    return YES;
}


//写大于20个字节的数据到特征
- (BOOL) readGetWiFiListResp:(LGCharacteristic *) characteristic {
    if(characteristic == nil) return NO;
    [EFShowView showHUDMsg:@"正在读取WiFi列表信息..."];
    kWeakSelf(self)

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_queue_create("com.dispatch.kyl", DISPATCH_QUEUE_CONCURRENT), ^{//设置一个异步线程组
        //接收服务1084的通知
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        int i=0, kk=0;
        static int bOK=0;
        for(i=0;i<100;i++){
            if(bOK) break;
            for(kk=0; kk<30; kk++){
                if(!weakself.bReqRecv) {
                    usleep(100000);
                    continue;
                }else break;
            }
            NSLog(@"3s_timeout, g_bReqRecv=%d", weakself.bReqRecv);
            [characteristic readValueWithBlock:^(NSData *data, NSError *error) {
                {
                    NSLog(@"读取数据：%@,len=%d",data, (int)[data length]);
                    const char *pDataOnce=[data bytes];
                    for(int i=0; i<[data length]; i++){
                        printf("0x%02X ", pDataOnce[i]&0xFF);
                        if((i!=0) && ((i+1)%8)==0) printf("   ");
                    }
                    printf("\n");
                    
                    if([data length]>1){
                        memcpy(weakself.pDataBuf+weakself.nDataSize, pDataOnce, (int)[data length]);
                        weakself.nDataSize+=(int)[data length];
                        printf("g_nDataSize=%d\n", weakself.nDataSize);
                    }
                    dispatch_semaphore_signal(sema);
                    
                    if(weakself.nDataSize >= sizeof(RES_WIFI_LIST)){
                        bOK=1;
                        //得到结构体
                        RES_WIFI_LIST stResp;
                        memset(&stResp, 0, sizeof(RES_WIFI_LIST));
                        memcpy(&stResp, weakself.pDataBuf, sizeof(RES_WIFI_LIST));
                        
                        queueMainStart
                        NSString *strMsg= [NSString stringWithFormat:@"成功读取数据,datalen=%d",weakself.nDataSize];
                        [weakself updateLog:strMsg];
                        [EFShowView HideHud];
                        
                        strMsg = [NSString stringWithFormat:@"准备解析数据 nRetCode=%d,nWifiNum=%d",stResp.nRetCode,stResp.nWifiNum];
                        [weakself updateLog:strMsg];
                        
                        strMsg = [NSString stringWithFormat:@"获取到的WiFi列表(%d):\n {{\n",stResp.nWifiNum];
                        [weakself updateLog:strMsg];
                        for (int i=0; i<stResp.nWifiNum; i++) {
                            NSString *wifiSSID = [NSString stringWithUTF8String:(char*)stResp.chSSID[i]];
                            strMsg = [NSString stringWithFormat:@"\n \t 第%d个WiFi信息：[ chSSID=%s,nSigStrength=%d,nAuthMode=%d,nEncryptType=%d,nChannel=%d,wifiSSID=%@ ]\n",i,stResp.chSSID[i],stResp.nSigStrength[i],stResp.nAuthMode[i],stResp.nEncryptType[i],stResp.nChannel[i],wifiSSID];
                            [weakself updateLog:strMsg];
                        }
                        strMsg = [NSString stringWithFormat:@"\n }}\n"];
                        [weakself updateLog:strMsg];
                        
                        queueEnd
                        
                    }
                }
            }];
            
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
    });
    return YES;
}

//写大于20个字节的数据到特征
- (BOOL) sendSetWiFiInfoCmd:(LGCharacteristic *) characteristic data:(NSData *) data{
    if(characteristic == nil) return NO;
    for (int i = 0; i < data.length; i+=20) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        dispatch_queue_t currentQueue = dispatch_get_current_queue() ;
#pragma clang diagnostic pop
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((i/20)*0.2 * NSEC_PER_SEC)), currentQueue, ^{
            
            NSUInteger subLength = data.length - i > 20 ? 20 : data.length-i ;
            NSData *subData = [data subdataWithRange:NSMakeRange(i, subLength)];
            
            NSLog(@"writeDataToCharacteristic 写入数据到特征chara=%@, datalen=%ld,",characteristic.UUIDString,[subData length]);
            [characteristic writeValue:subData completion:^(NSData *data,NSError *error) {
                // finnally disconnecting
                NSLog(@"成功写入数据到1803,2A06,error=%@,respdata=%@,respdatalen=%ld",error,data,[data length]);
                //[peripheral disconnectWithCompletion:nil];
                kWeakSelf(self)
                NSString *strMsg = [NSString stringWithFormat:@"成功写入数据到设备：datalen=%ld, ",[subData length]];
                [weakself updateLog:strMsg];
            }];//end for block writeValue
        });
    }
    
    return YES;
}

//获取设置WiFi的结果
-(BOOL) getSetWiFiResp:(LGCharacteristic *) characteristic{
    if (characteristic == nil) {
        return NO;
    }
    //因为设置wifi需要一段时间才能获得结果，所有需要主动去读取，回调立即返回没有数据
    //5秒钟后再主动读取特征值,对应小于20字节的数据，可以只读取一次，否则要多次读取，拼接数据包
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [characteristic readValueWithBlock:^(NSData *data, NSError *error) {
            NSLog(@"2秒钟后再主动读取特征值，RES_SET_WIFI_PARAM成功读取到数据：len=%ld",[data length]);
            RES_SET_WIFI_PARAM stResp;
            memset(&stResp, 0, sizeof(stResp));
            [data getBytes:&stResp length:sizeof(stResp)];
            kWeakSelf(self)
            NSString *strMsg = [NSString stringWithFormat:@"查询设置WiFi结果：datalen=%ld,RES_SET_WIFI_PARAM ret=%d,nHeaderFlag=%d,nOperType=%d, ",[data length],stResp.nRetCode ,stResp.nHeaderFlag,stResp.nHeaderFlag];
            [weakself updateLog:strMsg];
            [EFShowView HideHud];
        }];
    });
    return YES;
}

//写大于20个字节的数据到特征
- (BOOL) writeDataToCharacteristic:(LGCharacteristic *) characteristic data:(NSData *) data{
    if(characteristic == nil) return NO;
    for (int i = 0; i < data.length; i+=20) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        dispatch_queue_t currentQueue = dispatch_get_current_queue() ;
#pragma clang diagnostic pop
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((i/20)*0.2 * NSEC_PER_SEC)), currentQueue, ^{
            
            NSUInteger subLength = data.length - i > 20 ? 20 : data.length-i ;
            NSData *subData = [data subdataWithRange:NSMakeRange(i, subLength)];
            
            NSLog(@"writeDataToCharacteristic 写入数据到特征chara=%@, datalen=%ld,",characteristic.UUIDString,[subData length]);
            [characteristic writeValue:subData completion:^(NSData *data,NSError *error) {
                // finnally disconnecting
                NSLog(@"成功写入数据到1803,2A06,error=%@,respdata=%@,respdatalen=%ld",error,data,[data length]);
                //[peripheral disconnectWithCompletion:nil];

                
            }];//end for block writeValue
        });
    }
    
    return YES;
}

- (BOOL) readDataFromCharacteristic:(LGCharacteristic *) characteristic{
    if(characteristic == nil) return NO;
    [characteristic readValueWithBlock:^(NSData *data, NSError *error) {
        NSLog(@"成功读取到数据：len=%ld",[data length]);
        
    }];
    return YES;
}

#pragma mark - Table view data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_nDevices count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identified = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identified];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identified];
    }
    LGPeripheral *p = [_nDevices objectAtIndex:indexPath.row];
    cell.textLabel.text = p.name;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectPeripheral = [_nDevices objectAtIndex:indexPath.row];
    if(self.selectPeripheral.connected){
        //当前设备已经连接
        NSString *strMsg = [NSString stringWithFormat:@"当前选中设备：%@已经连接，你可以点击上面按钮发送请求了",self.selectPeripheral.name];
        self.lableConnectDescribe.text = strMsg;
    }
    else{
        NSString *strMsg = [NSString stringWithFormat:@"当前选中设备：%@未连接，请先连接设备再发送请求",self.selectPeripheral.name];
        self.lableConnectDescribe.text = strMsg;
        [self findService:self.selectPeripheral];
    }
}


@end
