"use client"

import { useEffect, useState } from "react"
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet"
import "leaflet/dist/leaflet.css"
import L from "leaflet"

// Fix for default Leaflet markers in Next.js
delete (L.Icon.Default.prototype as any)._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png",
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
})

const customMarkerIcon = new L.Icon({
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
  shadowSize: [41, 41],
})

// Auto-adjust bounds to fit all active markers
function BoundAdjuster({ coords }: { coords: [number, number][] }) {
  const map = useMap()
  
  useEffect(() => {
    if (coords.length > 0) {
      const bounds = L.latLngBounds(coords)
      // Add some padding so markers don't sit exactly on the edge
      map.fitBounds(bounds, { padding: [50, 50], maxZoom: 16 })
    }
  }, [coords, map])

  return null
}

interface RideLocation {
  id: string
  driverName?: string
  lat: number
  lng: number
  status: string
}

interface MapComponentProps {
  rides: RideLocation[]
}

export default function MapComponent({ rides }: MapComponentProps) {
  // Center roughly on India, or fall back to default if no rides
  const defaultCenter: [number, number] = [20.5937, 78.9629]
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return <div className="h-full w-full bg-slate-100 animate-pulse rounded-[2.5rem]" />
  }

  const markerCoords: [number, number][] = rides.map(r => [r.lat, r.lng])

  return (
    <div className="h-[600px] w-full rounded-[2.5rem] overflow-hidden z-0 isolate">
      <MapContainer 
        center={markerCoords.length > 0 ? markerCoords[0] : defaultCenter} 
        zoom={markerCoords.length > 0 ? 12 : 5} 
        style={{ height: "100%", width: "100%", zIndex: 0 }}
        zoomControl={false}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
        />
        
        {rides.map(ride => (
          <Marker 
            key={ride.id} 
            position={[ride.lat, ride.lng]}
            icon={customMarkerIcon}
          >
            <Popup className="rounded-xl">
              <div className="p-1">
                <p className="font-bold text-sm text-slate-900">{ride.driverName || "Driver"}</p>
                <div className="flex items-center gap-1 mt-1">
                  <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                  <span className="text-xs text-slate-500 font-medium uppercase">{ride.status}</span>
                </div>
              </div>
            </Popup>
          </Marker>
        ))}

        <BoundAdjuster coords={markerCoords} />
      </MapContainer>
    </div>
  )
}
