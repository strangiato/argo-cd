-- isInferenceServiceInRawDeploymentMode determines if the inference service deployed in RawDeployment mode
-- KServe v12 and above supports Rawdeployment for Inference graphs. For Inference services, KServe has supported RawDeployment model since [v0.7.0](https://github.com/kserve/kserve/releases/tag/v0.7.0).
function isInferenceServiceInRawDeploymentMode(obj)
  if obj.metadata.annotations == nil then
    return false
  end
  local deploymentMode = obj.metadata.annotations["serving.kserve.io/deploymentMode"]
  return deploymentMode ~= nil and deploymentMode == "RawDeployment"
end

local health_status = {}

health_status.status = "Progressing"
health_status.message = "Waiting for InferenceService to report status..."

if obj.status ~= nil then

  local progressing = false
  local degraded = false
  local status_false = 0
  local status_unknown = 0
  local msg = ""

  if obj.status.modelStatus ~= nil then
    if obj.status.modelStatus.transitionStatus ~= "UpToDate" then
      if obj.status.modelStatus.transitionStatus == "InProgress" then
        progressing = true
      else
        degraded = true
      end
      msg = msg .. "0: transitionStatus | " .. obj.status.modelStatus.transitionStatus .. "\n"
    end
  end
  
  if obj.status.conditions ~= nil then
    for i, condition in pairs(obj.status.conditions) do

      if condition.status == "Unknown" then
        status_unknown = status_unknown + 1
      elseif condition.status == "False" then
        status_false = status_false + 1
      end

      if condition.status ~= "True" then
        msg = msg .. i .. ": " .. condition.type .. " | " .. condition.status
        if condition.reason ~= nil and condition.reason ~= "" then
          msg = msg .. " | " .. condition.reason
        end
        if condition.message ~= nil and condition.message ~= "" then
          msg = msg .. " | " .. condition.message
        end
        msg = msg .. "\n"
      end

    end

    if progressing == false and degraded == false and status_unknown == 0 and status_false == 0 then
      health_status.status = "Healthy"
      msg = "InferenceService is healthy."
    elseif degraded == false and status_unknown >= 0 then
      health_status.status = "Progressing"
    else
      health_status.status = "Degraded"
    end

    health_status.message = msg
  end
end

return health_status
