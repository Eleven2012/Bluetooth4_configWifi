#ifndef __BT_DATA_TYPE_HREADER__
#define __BT_DATA_TYPE_HREADER__

#define	BTDATA_HEADER_FLAG				MAKEFOURCC('H','Y','B','T')
#define WIFI_LIST_NUM					16
#define MIN_DATA_LEN					8

#include  <sys/types.h>

typedef int                        HINT32;
typedef unsigned int            HUINT32;
typedef signed short            HINT16;
typedef unsigned short            HUINT16;
typedef            char            HCHAR;
typedef unsigned char            HUCHAR;
typedef signed char                HSCHAR;
typedef uint64_t                HUINT64;
typedef int64_t                    HINT64;
typedef float                    HFLOAT;
typedef double                    HDOUBLE;
typedef unsigned char            HBOOL;
typedef void                    HVOID;
typedef unsigned long            HULONG;
typedef long                    HLONG;
//typedef HVOID*                    HHANDLE;



#define MAKEFOURCC(ch0, ch1, ch2, ch3)                              \
((HUINT32)(HUCHAR)(ch0) | ((HUINT32)(HUCHAR)(ch1) << 8) |   \
((HUINT32)(HUCHAR)(ch2) << 16) | ((HUINT32)(HUCHAR)(ch3) << 24 ))

typedef enum
{
    E_WIFI_SECURITY_MODE_OPEN,            // 0: none
    E_WIFI_SECURITY_MODE_WEP,             // 1: WEP
    E_WIFI_SECURITY_MODE_WEP_64_ASCII,    // 2: WEP 64 ASCII
    E_WIFI_SECURITY_MODE_WEP_64_HEX,      // 3: WEP 64 HEX
    E_WIFI_SECURITY_MODE_WEP_128_ASCII,   // 4: WEP 128 ASCII
    E_WIFI_SECURITY_MODE_WEP_128_HEX,     // 5: WEP 128 HEX
    E_WIFI_SECURITY_MODE_WPAPSK_TKIP,     // 6: WPAPSK-TKIP
    E_WIFI_SECURITY_MODE_WPAPSK_AES,      // 7: WPAPSK-AES
    E_WIFI_SECURITY_MODE_WPA2PSK_TKIP,    // 8: WPA2PSK-TKIP
    E_WIFI_SECURITY_MODE_WPA2PSK_AES,     // 9: WPA2PSK-AES
    
    E_WIFI_SECURITY_MODE_ERR,            // 254:  err mode
    E_WIFI_SECURITY_MODE_UNKNOW,         // 255:UNKNOW
} E_WIFI_SECURITY_MODE;//WIFI加密模式

enum 
{
	WIFI_LIST_REQ		= 0,
	WIFI_LIST_RES		= 1,
	SETWIFI_PARAM_REQ   = 2,
	SETWIFI_PARAM_RES   = 3,
	GETWIFI_PARAM_REQ   = 4,
	GETWIFI_PARAM_RES   = 5,	
	RESET_IPC_REQ		= 6,	
	RESET_IPC_RES		= 7,	
};

/*请求wifi列表的结构体定义*/
typedef struct __tag_REQ_WIFI_LIST__
{
	HUINT32	nHeaderFlag;
	HUCHAR	nOperType;
	HCHAR    chReserve[3];
}REQ_WIFI_LIST,*PREQ_WIFI_LIST;

typedef struct __tag_RES_WIFI_LIST__
{
    HUINT32  nHeaderFlag;
    HUCHAR  nOperType;
    HCHAR   nRetCode;
    HCHAR    chReserve[2];
    /*wifi的数量*/
    HUINT32  nWifiNum;
    /*wifi的ssid*/
    HCHAR    chSSID[WIFI_LIST_NUM][32];
    /*信号强度0-100*/
    HCHAR  nSigStrength[WIFI_LIST_NUM];
    /*认证模式*/
    HCHAR  nAuthMode[WIFI_LIST_NUM];  // 0:NONE; 1:WEP; 2:WPA_Personal; 3:WPA2_Personal
    /*加密类型*/
    HCHAR  nEncryptType[WIFI_LIST_NUM];  // 0:TKIP; 1:AES
    HCHAR  nChannel[WIFI_LIST_NUM];
}RES_WIFI_LIST,*PRES_WIFI_LIST;

/*设置wifi参数的结构体定义*/
typedef struct __tag_REQ_SET_WIFI_PARAM__
{
	HUINT32						nHeaderFlag;
	HUCHAR						nOperType;
	HCHAR						chReserve[3];
	HCHAR						chSSID[128];
	HCHAR						chKey[128];	// wifi password
	E_WIFI_SECURITY_MODE		eWiFiSecurityMode;
	HCHAR						chReserve2[32];
}REQ_SET_WIFI_PARAM,*PREQ_SET_WIFI_PARAM;

typedef struct __tag_RES_SET_WIFI_PARAM__
{
	HUINT32		nHeaderFlag;
	HUCHAR		nOperType;
	HCHAR		chReserve[3];
	/*设置是否成功0表示设置成功 1表示连接成功 <0 表示连接失败*/
	HINT32		nRetCode;
}RES_SET_WIFI_PARAM,*PRES_SET_WIFI_PARAM;

/*读取wifi参数的结构体定义*/
typedef struct __tag_REQ_GET_WIFI_PARAM__
{
	HUINT32		nHeaderFlag;
	HUCHAR		nOperType;
	HCHAR		chReserve[3];
}REQ_GET_WIFI_PARAM,*PREQ_GET_WIFI_PARAM;


typedef struct __tag_RES_GET_WIFI_PARAM__
{
	HUINT32						nHeaderFlag;
	HUCHAR						nOperType;
	HCHAR						chReserve[3];
	HCHAR						chSSID[128];
	HCHAR						chKey[128];	// wifi password
	E_WIFI_SECURITY_MODE		eWiFiSecurityMode;
	/**/
	HINT32						nWifiStatus;
	char						nRetCode;
	char						chReserve2[31];
}RES_GET_WIFI_PARAM,*PRES_GET_WIFI_PARAM;

/*设备复位的结构体定义*/
typedef struct __tag_REQ_RESET_IPC__
{
	HUINT32		nHeaderFlag;
	HUCHAR		nOperType;
	HCHAR		chReserve[3];
}REQ_RESET_IPC,*PREQ_RESET_IPC;


typedef struct __tag_RES_RESET_IPC__
{
	HUINT32		nHeaderFlag;
	HUCHAR		nOperType;
	HCHAR		chReserve[3];
	HINT32		nRetCode;
}RES_RESET_IPC,*PRES_RESET_IPC;




#endif
