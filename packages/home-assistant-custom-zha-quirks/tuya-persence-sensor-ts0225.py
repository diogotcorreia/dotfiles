# Adapted from https://github.com/zigpy/zha-device-handlers/issues/2551
"""Device handler for Tuya ZG-205Z-A Mini 24Ghz human presence sensor."""

import math
from typing import Dict, Optional, Tuple, Union
from zigpy.profiles import zgp, zha
from zigpy.profiles.zha import DeviceType
from zigpy.quirks import CustomCluster, CustomDevice
import zigpy.types as t
from zigpy.zcl import foundation

from zigpy.zcl.clusters.general import (
    Basic,
    Identify,
    Ota,
    GreenPowerProxy,
    AnalogOutput,
    OnOff,
)
from zigpy.zcl.clusters.security import IasZone
from zigpy.zcl.clusters.measurement import (
    IlluminanceMeasurement,
    OccupancySensing,
)

from zhaquirks import MotionWithReset
from zhaquirks.const import (
    DEVICE_TYPE,
    ENDPOINTS,
    INPUT_CLUSTERS,
    MODELS_INFO,
    OUTPUT_CLUSTERS,
    PROFILE_ID,
)
from zhaquirks.tuya import (
    TuyaLocalCluster,
    TuyaManufCluster,
    TuyaNewManufCluster,
    TuyaZBE000Cluster,
    NoManufacturerCluster,
)

from zhaquirks.tuya.mcu import (
    DPToAttributeMapping,
    TuyaAttributesCluster,
    TuyaMCUCluster,
    TuyaOnOff,
)


class MotionCluster(MotionWithReset):
    """Motion cluster."""

    reset_s: int = 60


class TuyaOccupancySensing(OccupancySensing, TuyaLocalCluster):
    """Tuya local OccupancySensing cluster."""


class TuyaMmwRadarIndicator(TuyaAttributesCluster, OnOff):
    """AnalogOutput cluster for Large motion detection sensitivity."""


class TuyaMmwMotionState(TuyaAttributesCluster, AnalogOutput):
    """AnalogOutput cluster for Large motion detection sensitivity."""


class TuyaMmwRadarFadingTime(TuyaAttributesCluster, AnalogOutput):
    """AnalogOutput cluster for fading time."""

    def __init__(self, *args, **kwargs):
        """Init."""
        super().__init__(*args, **kwargs)
        self._update_attribute(self.attributes_by_name["description"].id, "Fading time")
        self._update_attribute(self.attributes_by_name["min_present_value"].id, 0)
        self._update_attribute(self.attributes_by_name["max_present_value"].id, 600)
        self._update_attribute(self.attributes_by_name["resolution"].id, 1)
        self._update_attribute(self.attributes_by_name["engineering_units"].id, 73)


class TuyaMmwRadarLargeMotionDetectionSensitivity(TuyaAttributesCluster, AnalogOutput):
    """AnalogOutput cluster for Large motion detection sensitivity."""

    def __init__(self, *args, **kwargs):
        """Init."""
        super().__init__(*args, **kwargs)
        self._update_attribute(
            self.attributes_by_name["description"].id, "Large motion sensitivity"
        )
        self._update_attribute(self.attributes_by_name["min_present_value"].id, 0)
        self._update_attribute(self.attributes_by_name["max_present_value"].id, 10)
        self._update_attribute(self.attributes_by_name["resolution"].id, 1)


class TuyaMmwRadarLargeMotionDetectionDistance(TuyaAttributesCluster, AnalogOutput):
    """AnalogOutput cluster for Large motion detection distance."""

    def __init__(self, *args, **kwargs):
        """Init."""
        super().__init__(*args, **kwargs)
        self._update_attribute(
            self.attributes_by_name["description"].id, "Large motion detection distance"
        )
        self._update_attribute(self.attributes_by_name["min_present_value"].id, 0)
        self._update_attribute(self.attributes_by_name["max_present_value"].id, 1000)
        self._update_attribute(self.attributes_by_name["resolution"].id, 10)
        self._update_attribute(self.attributes_by_name["engineering_units"].id, 118)


class TuyaMmwRadarSmallMotionDetectionSensitivity(TuyaAttributesCluster, AnalogOutput):
    """AnalogOutput cluster for Small motion detection sensitivity."""

    def __init__(self, *args, **kwargs):
        """Init."""
        super().__init__(*args, **kwargs)
        self._update_attribute(
            self.attributes_by_name["description"].id, "Small motion sensitivity"
        )
        self._update_attribute(self.attributes_by_name["min_present_value"].id, 0)
        self._update_attribute(self.attributes_by_name["max_present_value"].id, 10)
        self._update_attribute(self.attributes_by_name["resolution"].id, 1)


class TuyaMmwRadarSmallMotionDetectionDistance(TuyaAttributesCluster, AnalogOutput):
    """AnalogOutput cluster for Small motion detection distance."""

    def __init__(self, *args, **kwargs):
        """Init."""
        super().__init__(*args, **kwargs)
        self._update_attribute(
            self.attributes_by_name["description"].id, "Small motion detection distance"
        )
        self._update_attribute(self.attributes_by_name["min_present_value"].id, 0)
        self._update_attribute(self.attributes_by_name["max_present_value"].id, 600)
        self._update_attribute(self.attributes_by_name["resolution"].id, 10)
        self._update_attribute(self.attributes_by_name["engineering_units"].id, 118)


class TuyaMmwRadarStaticMotionDetectionSensitivity(TuyaAttributesCluster, AnalogOutput):
    """AnalogOutput cluster for Static motion detection sensitivity."""

    def __init__(self, *args, **kwargs):
        """Init."""
        super().__init__(*args, **kwargs)
        self._update_attribute(
            self.attributes_by_name["description"].id, "Static motion sensitivity"
        )
        self._update_attribute(self.attributes_by_name["min_present_value"].id, 0)
        self._update_attribute(self.attributes_by_name["max_present_value"].id, 10)
        self._update_attribute(self.attributes_by_name["resolution"].id, 1)


class TuyaMmwRadarStaticMotionDetectionDistance(TuyaAttributesCluster, AnalogOutput):
    """AnalogOutput cluster for Static motion detection distance."""

    def __init__(self, *args, **kwargs):
        """Init."""
        super().__init__(*args, **kwargs)
        self._update_attribute(
            self.attributes_by_name["description"].id,
            "Static motion detection distance",
        )
        self._update_attribute(self.attributes_by_name["min_present_value"].id, 0)
        self._update_attribute(self.attributes_by_name["max_present_value"].id, 600)
        self._update_attribute(self.attributes_by_name["resolution"].id, 10)
        self._update_attribute(self.attributes_by_name["engineering_units"].id, 118)


class TuyaMotionState(t.enum8):
    NONE = 0
    LARGE = 1
    SMALL = 2
    STATIC = 3


class MmwRadarManufCluster(NoManufacturerCluster, TuyaMCUCluster):
    """Tuya ZG-205Z-A Mini 24Ghz human presence sensor cluster."""

    attributes = TuyaMCUCluster.attributes.copy()
    attributes.update(
        {
            0xEF01: ("presence", t.uint32_t, True),
            0xEF02: ("large_sensitivity", t.uint32_t, True),
            0xEF04: ("large_distance", t.uint32_t, True),
            0xEF65: ("motion_state", TuyaMotionState, True),
            0xEF66: ("fading_time", t.uint32_t, True),
            0xEF68: ("small_distance", t.uint32_t, True),
            0xEF69: ("small_sensitivity", t.uint32_t, True),
            0xEF6A: ("illuminance_lux", t.uint32_t, True),
            0xEF6B: ("indicator", t.enum8, True),
            0xEF6C: ("static_distance", t.uint32_t, True),
            0xEF6D: ("static_sensitivity", t.uint32_t, True),
        }
    )

    dp_to_attribute: Dict[int, DPToAttributeMapping] = {
        1: DPToAttributeMapping(
            TuyaOccupancySensing.ep_attribute,
            "occupancy",
        ),
        2: DPToAttributeMapping(
            TuyaMmwRadarLargeMotionDetectionDistance.ep_attribute,
            "present_value",
            endpoint_id=3,
        ),
        4: DPToAttributeMapping(
            TuyaMmwRadarLargeMotionDetectionSensitivity.ep_attribute,
            "present_value",
            endpoint_id=4,
        ),
        102: DPToAttributeMapping(
            TuyaMmwRadarFadingTime.ep_attribute,
            "present_value",
            endpoint_id=2,
        ),
        104: DPToAttributeMapping(
            TuyaMmwRadarSmallMotionDetectionSensitivity.ep_attribute,
            "present_value",
            endpoint_id=6,
        ),
        105: DPToAttributeMapping(
            TuyaMmwRadarSmallMotionDetectionDistance.ep_attribute,
            "present_value",
            endpoint_id=5,
        ),
        107: DPToAttributeMapping(
            TuyaOnOff.ep_attribute,
            "on_off",
        ),
        108: DPToAttributeMapping(
            TuyaMmwRadarStaticMotionDetectionSensitivity.ep_attribute,
            "present_value",
            endpoint_id=8,
        ),
        109: DPToAttributeMapping(
            TuyaMmwRadarStaticMotionDetectionDistance.ep_attribute,
            "present_value",
            endpoint_id=7,
        ),
    }

    data_point_handlers = {
        1: "_dp_2_attr_update",
        2: "_dp_2_attr_update",
        4: "_dp_2_attr_update",
        102: "_dp_2_attr_update",
        104: "_dp_2_attr_update",
        105: "_dp_2_attr_update",
        107: "_dp_2_attr_update",
        108: "_dp_2_attr_update",
        109: "_dp_2_attr_update",
    }


class TS0225Radar(CustomDevice):
    """Quirk for Tuya ZG-205Z-A Mini 24Ghz human presence sensor."""

    signature = {
        #  endpoint=1, profile=260, device_type=1026, device_version=1,
        #  input_clusters=["0x0000", "0x0003", "0x0400", "0x0500","0xe000","0xe002", "0xee00", "0xef00"], output_clusters=[])
        MODELS_INFO: [("_TZE200_2aaelwxk", "TS0225")],
        ENDPOINTS: {
            1: {
                PROFILE_ID: zha.PROFILE_ID,
                DEVICE_TYPE: zha.DeviceType.IAS_ZONE,
                INPUT_CLUSTERS: [
                    Basic.cluster_id,
                    Identify.cluster_id,
                    IlluminanceMeasurement.cluster_id,
                    IasZone.cluster_id,
                    TuyaZBE000Cluster.cluster_id,
                    0xE002,  # Unknown
                    0xEE00,  # Unknown
                    TuyaNewManufCluster.cluster_id,
                ],
                OUTPUT_CLUSTERS: [],
            },
            242: {
                # "profile_id": "0xA1E0", "device_type": "0x0061",
                # "in_clusters": [], "out_clusters": ["0x0021"]
                PROFILE_ID: zgp.PROFILE_ID,
                DEVICE_TYPE: zgp.DeviceType.PROXY_BASIC,
                INPUT_CLUSTERS: [],
                OUTPUT_CLUSTERS: [GreenPowerProxy.cluster_id],
            },
        },
    }
    replacement = {
        ENDPOINTS: {
            1: {
                INPUT_CLUSTERS: [
                    Basic.cluster_id,
                    Identify.cluster_id,
                    IlluminanceMeasurement.cluster_id,
                    MotionCluster,
                    TuyaZBE000Cluster,
                    MmwRadarManufCluster,
                    TuyaOccupancySensing,
                    TuyaOnOff,
                ],
                OUTPUT_CLUSTERS: [],
            },
            2: {
                PROFILE_ID: zha.PROFILE_ID,
                DEVICE_TYPE: zha.DeviceType.COMBINED_INTERFACE,
                INPUT_CLUSTERS: [
                    TuyaMmwRadarFadingTime,
                ],
                OUTPUT_CLUSTERS: [],
            },
            3: {
                PROFILE_ID: zha.PROFILE_ID,
                DEVICE_TYPE: zha.DeviceType.COMBINED_INTERFACE,
                INPUT_CLUSTERS: [
                    TuyaMmwRadarLargeMotionDetectionSensitivity,
                ],
                OUTPUT_CLUSTERS: [],
            },
            4: {
                PROFILE_ID: zha.PROFILE_ID,
                DEVICE_TYPE: zha.DeviceType.COMBINED_INTERFACE,
                INPUT_CLUSTERS: [
                    TuyaMmwRadarLargeMotionDetectionDistance,
                ],
                OUTPUT_CLUSTERS: [],
            },
            5: {
                PROFILE_ID: zha.PROFILE_ID,
                DEVICE_TYPE: zha.DeviceType.COMBINED_INTERFACE,
                INPUT_CLUSTERS: [
                    TuyaMmwRadarSmallMotionDetectionSensitivity,
                ],
                OUTPUT_CLUSTERS: [],
            },
            6: {
                PROFILE_ID: zha.PROFILE_ID,
                DEVICE_TYPE: zha.DeviceType.COMBINED_INTERFACE,
                INPUT_CLUSTERS: [
                    TuyaMmwRadarSmallMotionDetectionDistance,
                ],
                OUTPUT_CLUSTERS: [],
            },
            7: {
                PROFILE_ID: zha.PROFILE_ID,
                DEVICE_TYPE: zha.DeviceType.COMBINED_INTERFACE,
                INPUT_CLUSTERS: [
                    TuyaMmwRadarStaticMotionDetectionSensitivity,
                ],
                OUTPUT_CLUSTERS: [],
            },
            8: {
                PROFILE_ID: zha.PROFILE_ID,
                DEVICE_TYPE: zha.DeviceType.COMBINED_INTERFACE,
                INPUT_CLUSTERS: [
                    TuyaMmwRadarStaticMotionDetectionDistance,
                ],
                OUTPUT_CLUSTERS: [],
            },
            9: {
                PROFILE_ID: zgp.PROFILE_ID,
                DEVICE_TYPE: zgp.DeviceType.PROXY_BASIC,
                INPUT_CLUSTERS: [],
                OUTPUT_CLUSTERS: [GreenPowerProxy.cluster_id],
            },
        },
    }


class TS0225RadarWithOutputClusters(TS0225Radar):
    """Quirk for Tuya ZG-205Z-A Mini 24Ghz human presence sensor."""

    signature = {
        #  endpoint=1, profile=260, device_type=1026, device_version=1,
        #  input_clusters=["0x0000", "0x0003", "0x0400", "0x0500","0xe000","0xe002", "0xee00", "0xef00"],
        #  output_clusters=["0x0003", "0xe000", "0xe002", "0xee00", "0xef00"])
        MODELS_INFO: [("_TZE200_2aaelwxk", "TS0225")],
        ENDPOINTS: {
            1: {
                PROFILE_ID: zha.PROFILE_ID,
                DEVICE_TYPE: zha.DeviceType.IAS_ZONE,
                INPUT_CLUSTERS: [
                    Basic.cluster_id,
                    Identify.cluster_id,
                    IlluminanceMeasurement.cluster_id,
                    IasZone.cluster_id,
                    TuyaZBE000Cluster.cluster_id,
                    0xE002,  # Unknown
                    0xEE00,  # Unknown
                    TuyaNewManufCluster.cluster_id,
                ],
                OUTPUT_CLUSTERS: [
                    Identify.cluster_id,
                    TuyaZBE000Cluster.cluster_id,
                    0xE002,  # Unknown
                    0xEE00,  # Unknown
                    TuyaNewManufCluster.cluster_id,
                ],
            },
            242: {
                # "profile_id": "0xA1E0", "device_type": "0x0061",
                # "in_clusters": [], "out_clusters": ["0x0021"]
                PROFILE_ID: zgp.PROFILE_ID,
                DEVICE_TYPE: zgp.DeviceType.PROXY_BASIC,
                INPUT_CLUSTERS: [],
                OUTPUT_CLUSTERS: [GreenPowerProxy.cluster_id],
            },
        },
    }
