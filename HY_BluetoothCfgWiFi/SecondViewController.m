//
//  SecondViewController.m
//  HY_BluetoothCfgWiFi
//
//  Created by 孔雨露 on 2018/5/4.
//  Copyright © 2018年 孔雨露. All rights reserved.
//

#import "SecondViewController.h"
#import "BTDataType.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#import "EasyUtils.h"
#import "EFShowView.h"
#import "EasyBlueToothManager.h"
#import "ToolCell.h"
#import "EasyService.h"
#import "EasyDescriptor.h"

static NSString * SERVICEID = @"1803";
static NSString * CHARACTERISTICID = @"2A06";

static const int BUF_SIZE = 600;

typedef NS_ENUM(NSInteger, YH_RequestType) {
    
    YH_RequestType_GetWiFiList = 0,    //获取摄像机WiFi列表
    YH_RequestType_SetWiFi = 1,    //设置摄像机WiFi
    YH_RequestType_GetWiFiParam = 2,    //获取摄像机当前设置的WiFi信息
    YH_RequestType_Reset = 3    //重置摄像机
};


@interface SecondViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    int count;
    int nSelectRow;
}
@property (weak, nonatomic) IBOutlet UIButton *btnSearch;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *labelServiceUUID;
@property (weak, nonatomic) IBOutlet UILabel *labelCharactistUUID;
@property (weak, nonatomic) IBOutlet UITextField *textFieldServiceUUID;
@property (weak, nonatomic) IBOutlet UITextField *textFieldCharactistUUID;
@property (weak, nonatomic) IBOutlet UIButton *btnGetWifiList;
@property (weak, nonatomic) IBOutlet UIButton *btnGetWifiInfo;
@property (weak, nonatomic) IBOutlet UIButton *btnReset;
@property (weak, nonatomic) IBOutlet UIButton *btn1;
@property (weak, nonatomic) IBOutlet UIButton *btn2;
@property (weak, nonatomic) IBOutlet UIButton *btn3;
@property (weak, nonatomic) IBOutlet UILabel *labelWiFiSSID;
@property (weak, nonatomic) IBOutlet UILabel *labelWiFiPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldWiFiSSID;
@property (weak, nonatomic) IBOutlet UITextField *textFieldWIFiPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnSetWiFi;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;

@property (nonatomic, copy) NSString *cameraDid;
@property (nonatomic, copy) NSString *wifiSsid;
@property (nonatomic, copy) NSString *wifPassword;
@property (nonatomic, copy) NSString *serviceUUID;
@property (nonatomic, copy) NSString *characUUID;

@property (nonatomic,strong)NSMutableArray *dataArray ;
@property (nonatomic,strong)EasyCenterManager  *centerManager ;

@property (nonatomic, strong) EasyPeripheral *selectPeripheral;
@property (nonatomic, strong) EasyService *selectService;
@property (nonatomic, strong) EasyCharacteristic *selectCharacteristic;
@property (nonatomic, assign) int  bReqRecv;
@property (nonatomic, assign) int  nDataSize;
@property (nonatomic, assign) char *pDataBuf;

@end

@implementation SecondViewController

-(void) dealloc{
    if(_pDataBuf){
        free(_pDataBuf);
        _pDataBuf = NULL;
    }
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //[self.centerManager startScanDevice];
    
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //[self.centerManager stopScanDevice];
    
}



- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化数据
    self.bReqRecv = 0;
    self.nDataSize = 0;
    _pDataBuf = malloc(BUF_SIZE);
    memset(_pDataBuf, 0, BUF_SIZE);
    //1.纯代码自定义的cell注册如下：
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ToolCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([ToolCell class])];
    //[self.tableView registerClass:[HMStatusCell class] forCellReuseIdentifier:ID];
    //[self.tableView registerClass:[ToolCell class] forCellReuseIdentifier:@"ToolCell"];
    //2. 使用Xib自定义的cell,注册如下
    //[self.tableView registerNib:[UINib nibWithNibName:@"WZUserCell" bundle:nil] forCellReuseIdentifier:UserCellId];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.cameraDid = @"VIEW-747390-SGLEV";
    self.wifiSsid = [self fetchSSIDInfo];
    self.wifPassword = @"790511kyl";
    self.serviceUUID = SERVICEID;
    self.characUUID = CHARACTERISTICID;
    self.wifiSsid = [self fetchSSIDInfo];
    
    [self updateUI];
    nSelectRow = 0;
    
}

-(void) updateUI{
    
    self.textFieldWiFiSSID.text = self.wifiSsid;
    self.textFieldWIFiPassword.text = self.wifPassword;
    self.textFieldServiceUUID.text = self.serviceUUID;
    self.textFieldCharactistUUID.text = self.characUUID;
    
}

-(void) getUIInput{
    
    self.wifiSsid = self.textFieldWiFiSSID.text;
    self.wifPassword = self.textFieldWIFiPassword.text;
    self.characUUID = self.textFieldCharactistUUID.text;
    self.serviceUUID = self.textFieldServiceUUID.text;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnSearchClicked:(id)sender {
    [self scanDevice];
}
- (IBAction)btnStopClicked:(id)sender {
    [self stopScan];
}
- (IBAction)btnGetWiFiListClicked:(id)sender {
    NSString *strPerName = self.selectPeripheral.name;
    if (self.selectPeripheral.state==CBPeripheralStateConnected) {
        NSString *strMsg= [NSString stringWithFormat:@"设备:%@ 已经连接,准备发送获取WiFi列表请求",strPerName];
        [self updateLog:strMsg];
        //获取1803服务和2A06特征
        self.selectService = [self getService:self.selectPeripheral serviceUUID:self.serviceUUID];
        self.selectCharacteristic = [self getCharact:self.selectService charactUUID:self.characUUID];
        if(self.selectService == nil || self.selectService.name == nil){
            strMsg= [NSString stringWithFormat:@"设备:%@ 没有找到服务：%@",strPerName,self.serviceUUID];
            [self updateLog:strMsg];
            return;
        }
        if(self.selectCharacteristic == nil || self.selectCharacteristic.name == nil){
            strMsg= [NSString stringWithFormat:@"设备:%@ 没有找到特征：%@",strPerName,self.characUUID];
            [self updateLog:strMsg];
            return;
        }
        //开始发送请求
        strMsg= [NSString stringWithFormat:@"设备:%@ 找到特征：%@，正在发送请求",strPerName,self.characUUID];
        [self updateLog:strMsg];
        memset(_pDataBuf, 0, sizeof(BUF_SIZE));
        _nDataSize=0;
        _bReqRecv=0;
        
        REQ_WIFI_LIST stReq;
        memset(&stReq, 0, sizeof(stReq));
        stReq.nHeaderFlag = BTDATA_HEADER_FLAG;
        stReq.nOperType = WIFI_LIST_REQ;
        NSData * msgData = [[NSData alloc] initWithBytes:&stReq length:sizeof(REQ_WIFI_LIST)];
        [EFShowView showHUDMsg:@"正在获取WiFi列表..." ];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EFShowView HideHud];
        });
        kWeakSelf(self)
        [self.selectCharacteristic writeValueWithData:msgData callback:^(EasyCharacteristic *characteristic, NSData *data, NSError *error) {
            
            const char *pDataOnce=[data bytes];
            for(int i=0; i<[data length]; i++){
                printf("0x%02X ", pDataOnce[i]&0xFF);
                if((i!=0) && ((i+1)%8)==0) printf("   ");
            }
            printf("\n");
            weakself.bReqRecv=1;
            
            queueMainStart
            NSString *strMsg= [NSString stringWithFormat:@"往设备:%@ 的特征：%@成功写入数据,datalen=%ld",strPerName,weakself.characUUID,[data length]];
            [weakself updateLog:strMsg];
            
            queueEnd
        }];
        [weakself readWiFiListRespData];
        
    }
    else{
        NSString *strMsg= [NSString stringWithFormat:@"设备:%@ 已断开连接，请先从新连接",strPerName];
        [self updateLog:strMsg];
        [self reconnetDevice:self.selectPeripheral];
    }
}

- (void) readWiFiListRespData{
    kWeakSelf(self)
    NSString * strPerName = self.selectPeripheral.name;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_queue_create("com.dispatch.EasyBlueTooth", DISPATCH_QUEUE_CONCURRENT), ^{//设置一个异步线程组
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
            
            [weakself.selectCharacteristic readValueWithCallback:^(EasyCharacteristic *characteristic, NSData *data, NSError *error) {
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
                    NSString *strMsg= [NSString stringWithFormat:@"往设备:%@ 的特征：%@成功读取数据,datalen=%d",strPerName,weakself.characUUID,weakself.nDataSize];
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
            }];
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
    });
}


- (IBAction)btnGetWiFiInfoClicked:(id)sender {
    NSString *strPerName = self.selectPeripheral.name;
    if (self.selectPeripheral.state==CBPeripheralStateConnected) {
        NSString *strMsg= [NSString stringWithFormat:@"设备:%@ 已经连接,准备发送获取设备WiFi信息请求",strPerName];
        [self updateLog:strMsg];
        //获取1803服务和2A06特征
        self.selectService = [self getService:self.selectPeripheral serviceUUID:self.serviceUUID];
        self.selectCharacteristic = [self getCharact:self.selectService charactUUID:self.characUUID];
        if(self.selectService == nil || self.selectService.name == nil){
            strMsg= [NSString stringWithFormat:@"设备:%@ 没有找到服务：%@",strPerName,self.serviceUUID];
            [self updateLog:strMsg];
            return;
        }
        if(self.selectCharacteristic == nil || self.selectCharacteristic.name == nil){
            strMsg= [NSString stringWithFormat:@"设备:%@ 没有找到特征：%@",strPerName,self.characUUID];
            [self updateLog:strMsg];
            return;
        }
        //开始发送请求
        strMsg= [NSString stringWithFormat:@"设备:%@ 找到特征：%@，正在发送请求",strPerName,self.characUUID];
        [self updateLog:strMsg];
        memset(_pDataBuf, 0, sizeof(BUF_SIZE));
        _nDataSize=0;
        _bReqRecv=0;
        
        REQ_GET_WIFI_PARAM stReq;
        memset(&stReq, 0, sizeof(stReq));
        stReq.nHeaderFlag = BTDATA_HEADER_FLAG;
        stReq.nOperType = GETWIFI_PARAM_REQ;
        NSData * msgData = [[NSData alloc] initWithBytes:&stReq length:sizeof(stReq)];
        [EFShowView showHUDMsg:@"正在获取设备WiFi信息..." ];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EFShowView HideHud];
        });
        kWeakSelf(self)
        [self.selectCharacteristic writeValueWithData:msgData callback:^(EasyCharacteristic *characteristic, NSData *data, NSError *error) {
            
            const char *pDataOnce=[data bytes];
            for(int i=0; i<[data length]; i++){
                printf("0x%02X ", pDataOnce[i]&0xFF);
                if((i!=0) && ((i+1)%8)==0) printf("   ");
            }
            printf("\n");

            weakself.bReqRecv=1;
            queueMainStart
            NSString *strMsg= [NSString stringWithFormat:@"往设备:%@ 的特征：%@成功写入数据,datalen=%ld",strPerName,weakself.characUUID,[data length]];
            [weakself updateLog:strMsg];
            
            queueEnd
        }];
        [weakself readGetWiFiResp:weakself.selectCharacteristic];
        
    }
    else{
        NSString *strMsg= [NSString stringWithFormat:@"设备:%@ 已断开连接，请先从新连接",strPerName];
        [self updateLog:strMsg];
        [self reconnetDevice:self.selectPeripheral];
    }
}

-(BOOL) readGetWiFiResp:(EasyCharacteristic *) characteristic{
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
            [characteristic readValueWithCallback:^(EasyCharacteristic *characteristic, NSData *data, NSError *error)  {
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


- (IBAction)btnResetClicked:(id)sender {
    NSString *strPerName = self.selectPeripheral.name;
    if (self.selectPeripheral.state==CBPeripheralStateConnected) {
        NSString *strMsg= [NSString stringWithFormat:@"设备:%@ 已经连接,准备发送重置摄像机请求",strPerName];
        [self updateLog:strMsg];
        //获取1803服务和2A06特征
        self.selectService = [self getService:self.selectPeripheral serviceUUID:self.serviceUUID];
        self.selectCharacteristic = [self getCharact:self.selectService charactUUID:self.characUUID];
        if(self.selectService == nil || self.selectService.name == nil){
            strMsg= [NSString stringWithFormat:@"设备:%@ 没有找到服务：%@",strPerName,self.serviceUUID];
            [self updateLog:strMsg];
            return;
        }
        if(self.selectCharacteristic == nil || self.selectCharacteristic.name == nil){
            strMsg= [NSString stringWithFormat:@"设备:%@ 没有找到特征：%@",strPerName,self.characUUID];
            [self updateLog:strMsg];
            return;
        }
        //开始发送请求
        strMsg= [NSString stringWithFormat:@"设备:%@ 找到特征：%@，正在发送请求",strPerName,self.characUUID];
        [self updateLog:strMsg];
        memset(_pDataBuf, 0, sizeof(BUF_SIZE));
        _nDataSize=0;
        _bReqRecv=0;
        
        REQ_SET_WIFI_PARAM stReq;
        memset(&stReq, 0, sizeof(stReq));
        stReq.nHeaderFlag = BTDATA_HEADER_FLAG;
        stReq.nOperType = SETWIFI_PARAM_REQ;
        strcpy(stReq.chSSID,[self.wifiSsid UTF8String]);
        strcpy(stReq.chKey,[self.wifPassword UTF8String]);
        stReq.eWiFiSecurityMode = E_WIFI_SECURITY_MODE_UNKNOW;
        NSData * msgData = [[NSData alloc] initWithBytes:&stReq length:sizeof(stReq)];
        [EFShowView showHUDMsg:@"正在重置摄像机..." ];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EFShowView HideHud];
        });
        kWeakSelf(self)
        [self.selectCharacteristic writeValueWithData:msgData callback:^(EasyCharacteristic *characteristic, NSData *data, NSError *error) {
            
            const char *pDataOnce=[data bytes];
            for(int i=0; i<[data length]; i++){
                printf("0x%02X ", pDataOnce[i]&0xFF);
                if((i!=0) && ((i+1)%8)==0) printf("   ");
            }
            printf("\n");

            
            queueMainStart
            NSString *strMsg= [NSString stringWithFormat:@"往设备:%@ 的特征：%@成功写入数据,datalen=%ld",strPerName,weakself.characUUID,[data length]];
            [weakself updateLog:strMsg];
            
            queueEnd
        }];
        [weakself readResetResp];
        
    }
    else{
        NSString *strMsg= [NSString stringWithFormat:@"设备:%@ 已断开连接，请先从新连接",strPerName];
        [self updateLog:strMsg];
        [self reconnetDevice:self.selectPeripheral];
    }
}

-(void) readResetResp{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{//启动线程
        // Do a taks in the background
        for(int i=0;i<1;i++)
        {
            usleep(10000);
            kWeakSelf(self)
            [weakself.selectCharacteristic readValueWithCallback:^(EasyCharacteristic *characteristic, NSData *data, NSError *error) {
                NSLog(@"读取数据：%@,len=%zd",data,[data length]);
                if ([data length] > 1) {
                    //得到结构体
                    RES_RESET_IPC stResp;
                    memset(&stResp, 0, sizeof(stResp));
                    [data getBytes:&stResp length:sizeof(stResp)];
                    dispatch_async(dispatch_get_main_queue(), ^{ //回到主线程
                        [EFShowView HideHud];
                        NSString *strMsg = [NSString stringWithFormat:@"读取重置摄像机 请求数据响应 datelen=%ld：nRetCode=%d",[data length],stResp.nRetCode];
                        [weakself updateLog:strMsg];
                        
                    });
                }
            }];
        }
    });
}

- (IBAction)btn1Clicked:(id)sender {
}
- (IBAction)btn2Clicked:(id)sender {
}
- (IBAction)btn3Clicked:(id)sender {
}
- (IBAction)btnSetWiFiClicked:(id)sender {
    NSString *strPerName = self.selectPeripheral.name;
    if (self.selectPeripheral.state==CBPeripheralStateConnected) {
        NSString *strMsg= [NSString stringWithFormat:@"设备:%@ 已经连接,准备发送设置WiFi请求",strPerName];
        [self updateLog:strMsg];
        //获取1803服务和2A06特征
        self.selectService = [self getService:self.selectPeripheral serviceUUID:self.serviceUUID];
        self.selectCharacteristic = [self getCharact:self.selectService charactUUID:self.characUUID];
        if(self.selectService == nil || self.selectService.name == nil){
            strMsg= [NSString stringWithFormat:@"设备:%@ 没有找到服务：%@",strPerName,self.serviceUUID];
            [self updateLog:strMsg];
            return;
        }
        if(self.selectCharacteristic == nil || self.selectCharacteristic.name == nil){
            strMsg= [NSString stringWithFormat:@"设备:%@ 没有找到特征：%@",strPerName,self.characUUID];
            [self updateLog:strMsg];
            return;
        }
        //开始发送请求
        strMsg= [NSString stringWithFormat:@"设备:%@ 找到特征：%@，正在发送请求",strPerName,self.characUUID];
        [self updateLog:strMsg];
        memset(_pDataBuf, 0, sizeof(BUF_SIZE));
        _nDataSize=0;
        _bReqRecv=0;
        
        REQ_SET_WIFI_PARAM stReq;
        memset(&stReq, 0, sizeof(stReq));
        stReq.nHeaderFlag = BTDATA_HEADER_FLAG;
        stReq.nOperType = SETWIFI_PARAM_REQ;
        strcpy(stReq.chSSID,[self.wifiSsid UTF8String]);
        strcpy(stReq.chKey,[self.wifPassword UTF8String]);
        stReq.eWiFiSecurityMode = E_WIFI_SECURITY_MODE_UNKNOW;
        NSData * msgData = [[NSData alloc] initWithBytes:&stReq length:sizeof(stReq)];
        [EFShowView showHUDMsg:@"正在设置WiFi..." ];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [EFShowView HideHud];
        });
        kWeakSelf(self)
        [self.selectCharacteristic writeValueWithData:msgData callback:^(EasyCharacteristic *characteristic, NSData *data, NSError *error) {
            
            const char *pDataOnce=[data bytes];
            for(int i=0; i<[data length]; i++){
                printf("0x%02X ", pDataOnce[i]&0xFF);
                if((i!=0) && ((i+1)%8)==0) printf("   ");
            }
            printf("\n");
            weakself.bReqRecv=1;
            
            queueMainStart
            NSString *strMsg= [NSString stringWithFormat:@"往设备:%@ 的特征：%@成功写入数据,datalen=%ld",strPerName,weakself.characUUID,[data length]];
            [weakself updateLog:strMsg];
            
            queueEnd
        }];
        [weakself readSetWiFiResp];
        
    }
    else{
        NSString *strMsg= [NSString stringWithFormat:@"设备:%@ 已断开连接，请先从新连接",strPerName];
        [self updateLog:strMsg];
        [self reconnetDevice:self.selectPeripheral];
    }
}

-(void) readSetWiFiResp {
    NSString *strPerName = self.selectPeripheral.name;
    static int bOK=0;
    int i=0, k=0;
    // Do a taks in the background
    for(i=0;i<1;i++)
    {
        if(bOK) break;
        for(k=0;k<50;k++){
            if(self.bReqRecv) break;
            else{
                usleep(100000);
                continue;
            }
        }
        NSLog(@"3s_timeout, g_bReqRecv=%d k=%d", self.bReqRecv, k);
        
        kWeakSelf(self)
        [weakself.selectCharacteristic readValueWithCallback:^(EasyCharacteristic *characteristic, NSData *data, NSError *error){
            NSLog(@"SETWIFI_PARAM_RESP 读取数据：%@,len=%u",data, [data length]);
            if ([data length] > 1) {
                bOK=1;
                //得到结构体
                RES_SET_WIFI_PARAM stResp;
                memset(&stResp, 0, sizeof(stResp));
                [data getBytes:&stResp length:sizeof(stResp)];
                
                queueMainStart
                [EFShowView HideHud];
                NSString *strMsg= [NSString stringWithFormat:@"往设备:%@ 的特征：%@成功读取到设置WiFi响应数据,datalen=%ld，retcode=%d",strPerName,weakself.characUUID,[data length],stResp.nRetCode];
                [weakself updateLog:strMsg];
                
                queueEnd
                
            }
        }];
    }
}


#pragma mark - tableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ToolCell cellHeight] ;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ToolCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ToolCell class]) forIndexPath:indexPath];
    cell.peripheral = self.dataArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.centerManager stopScanDevice];
    nSelectRow = (int)indexPath.row;
    kWeakSelf(self)
    EasyPeripheral *peripheral = self.dataArray[indexPath.row];
    self.selectPeripheral = peripheral;
    NSString *strPerName = peripheral.name;
    if (peripheral.state==CBPeripheralStateConnected) {
        NSString *strMsg= [NSString stringWithFormat:@"选择设备:%@ 已经连接",strPerName];
        [weakself updateLog:strMsg];
    }
    else{
        [weakself reconnetDevice:peripheral];
    }
}


#pragma mark - getter
- (NSMutableArray *)dataArray
{
    if (nil == _dataArray) {
        _dataArray  =[NSMutableArray arrayWithCapacity:10];
    }
    return _dataArray ;
}
- (EasyCenterManager *)centerManager
{
    if (nil == _centerManager) {
        
        dispatch_queue_t queue = dispatch_queue_create("com.easyBluetootth.demo", 0);
        _centerManager = [[EasyCenterManager alloc]initWithQueue:queue options:nil];
    }
    return _centerManager ;
}



-(void) scanDevice{
    kWeakSelf(self)
    [self.centerManager scanDeviceWithTimeInterval:6 services:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey: @YES }  callBack:^(EasyPeripheral *peripheral, searchFlagType searchType) {
        if (peripheral) {
            if (searchType&searchFlagTypeChanged) {
                //NSInteger perpheralIndex = [weakself.dataArray indexOfObject:peripheral];
                //[weakself.dataArray replaceObjectAtIndex:perpheralIndex withObject:peripheral];
            }
            else if(searchType&searchFlagTypeAdded){
                //过滤设备，只添加HY开通的慧眼设备
                if([peripheral.name hasPrefix:@"HY"])
                {
                    [weakself.dataArray addObject:peripheral];
                    queueMainStart
                    NSString *strMsg= [NSString stringWithFormat:@"搜索到慧眼设备:%@",peripheral.name];
                    [weakself updateLog:strMsg];
                    queueEnd
                }
            }
            else if (searchType&searchFlagTypeDisconnect || searchType&searchFlagTypeDelete){
                //[weakself.dataArray removeObject:peripheral];
            }
            queueMainStart
            [weakself.tableView reloadData];
            queueEnd
        }
    }];
    
    self.centerManager.stateChangeCallback = ^(EasyCenterManager *manager, CBManagerState state) {
        [weakself managerStateChanged:state];
    };
}

-(void) stopScan{
    [self.centerManager stopScanDevice];
}

#pragma mark - bluetooth callback

- (void)managerStateChanged:(CBManagerState)state
{
    queueMainStart
    if (state == CBManagerStatePoweredOn) {
        UIView *coverView = [[UIApplication sharedApplication].keyWindow viewWithTag:1011];
        if (coverView) {
            [coverView removeFromSuperview];
            coverView = nil ;
        }
        
        UIViewController *vc = [EasyUtils topViewController];
        if ([vc isKindOfClass:[self class]]) {
            [self.centerManager startScanDevice];
        }
        
    }
    else if (state == CBManagerStatePoweredOff){
        UILabel *coverLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        coverLabel.font = [UIFont systemFontOfSize:20];
        coverLabel.tag = 1011 ;
        coverLabel.textAlignment = NSTextAlignmentCenter ;
        coverLabel.text = @"系统蓝牙已关闭，请打开系统蓝牙";
        coverLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        [[UIApplication sharedApplication].keyWindow addSubview:coverLabel];
    }
    queueEnd
}

-(void) reconnetDevice:(EasyPeripheral *)peripheral{
    [EFShowView showHUDMsg:@"正在连接设备..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [EFShowView HideHud];
    });
    NSString *strPerName = self.selectPeripheral.name;
    NSString *strMsg= [NSString stringWithFormat:@"选择设备:%@，正在连接",strPerName];
    [self updateLog:strMsg];
    kWeakSelf(self)
    [peripheral connectDeviceWithCallback:^(EasyPeripheral *perpheral, NSError *error, deviceConnectType deviceConnectType) {
        
        queueMainStart
        if (deviceConnectType == deviceConnectTypeDisConnect) {
            [EFShowView HideHud];
            NSString *strMsg= [NSString stringWithFormat:@"选择设备:%@，连接断开",strPerName];
            [weakself updateLog:strMsg];
            [EFShowView showAlertMessageWithTitle:@"设备失去连接" contentMessage:error.localizedDescription cancelTitle:@"重新连接" cancelCallBack:^{
                //重新连接设备
                [self.selectPeripheral reconnectDevice];
            } sureTitle:@"取消" sureCallBack:^{
                
            }];
        }
        else{
            [EFShowView HideHud];
            if (error) {
                [EFShowView showErrorText:error.domain];
                NSString *strMsg= [NSString stringWithFormat:@"选择设备:%@，连接失败，错误码:%@",strPerName,error.domain];
                [weakself updateLog:strMsg];
            }
            else{
                NSString *strMsg= [NSString stringWithFormat:@"选择设备:%@，连接成功",strPerName];
                [weakself updateLog:strMsg];
                //开始发现服务和特征
                [weakself findServiceAndCharactis:peripheral];
            }
        }
        queueEnd
    }];
}

//发现蓝牙设备的服务和特征
- (void) findServiceAndCharactis:(EasyPeripheral *) peripheral{
    kWeakSelf(self)
    [EFShowView showHUDMsg:@"获取服务..." ];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [EFShowView HideHud];
    });
    [peripheral discoverAllDeviceServiceWithCallback:^(EasyPeripheral *peripheral, NSArray<EasyService *> *serviceArray, NSError *error) {
        
        NSLog(@"%@  == %@",serviceArray,error);
        queueMainStart
        NSString *strMsg= [NSString stringWithFormat:@"发现了服务数量：%ld",[serviceArray count] ];
        [weakself updateLog:strMsg];
        queueEnd
        
        for (EasyService *tempS in serviceArray) {
            NSLog(@" %@  = %@",tempS.UUID ,tempS.description);
            
            [tempS discoverCharacteristicWithCallback:^(NSArray<EasyCharacteristic *> *characteristics, NSError *error) {
                NSLog(@" %@  = %@",characteristics , error );
                queueMainStart
                NSString *strMsg= [NSString stringWithFormat:@"发现了特征数量：%ld",[characteristics count] ];
                [weakself updateLog:strMsg];
                queueEnd
                for (EasyCharacteristic *tempC in characteristics) {
                    [tempC discoverDescriptorWithCallback:^(NSArray<EasyDescriptor *> *descriptorArray, NSError *error) {
                        NSLog(@"%@ ====", descriptorArray)  ;
                        if (descriptorArray.count > 0) {
                            for (EasyDescriptor *d in descriptorArray) {
                                NSLog(@"%@ - %@ %@ ", d,d.UUID ,d.value);
                            }
                        }
                        for (EasyDescriptor *desc in descriptorArray) {
                            [desc readValueWithCallback:^(EasyDescriptor *descriptor, NSError *error) {
                                NSLog(@"读取descriptor的值：%@ ,%@ ",descriptor.value,error);
                            }];
                        }
                        queueMainStart
                        [EFShowView HideHud];
                        queueEnd
                    }];
                }
            }];
        }
    }];
}

- (EasyService *) getService:(EasyPeripheral *) peripheral serviceUUID:(NSString *) serviceUUID{
    if (peripheral == nil || serviceUUID == nil) {
        return nil;
    }
    EasyService *service = nil;
    for (int i=0; i < [peripheral.serviceArray count]; i++) {
        service = [peripheral.serviceArray objectAtIndex:i];
        if ([serviceUUID compare:service.name options:NSCaseInsensitiveSearch|NSNumericSearch] == NSOrderedSame) {
            return service;
        }
    }
    return service;
}

-(EasyCharacteristic *) getCharact:(EasyService *) service charactUUID:(NSString *) charactUUID{
    if (service == nil || charactUUID == nil) {
        return nil;
    }
    EasyCharacteristic *charact = nil;
    for (int i=0; i < [service.characteristicArray count]; i++) {
        charact = [service.characteristicArray objectAtIndex:i];
        if ([charactUUID compare:charact.name options:NSCaseInsensitiveSearch|NSNumericSearch] == NSOrderedSame) {
            return charact;
        }
    }
    return charact;
}


@end
