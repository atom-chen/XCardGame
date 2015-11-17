--cProps �������ݣ���ս������ڵ�����
--cItem ���ߵ�Ԫ����ս������Ļ�ϵ�һ�����ֵ�λ

cItem = class("cItem", cUnit)

function cItem:ctor( unitType, cfg )
    cUnit.ctor( self, unitType, nil )

    self.classify = 0           -- ���߷���: 0-���, 1-����, 2-����
    self.count = 0              -- ��������,��Ҫ��Խ��
    self.dampingX = 0.0         -- X���������ϵ��
    self.initSpeed = 0.0        -- ��ʼ�ٶ�
    self.following = false      -- һ���������������ں�,�ͽ�һֱ����
    self.followDistance = 0     -- ����ɻ�����,ȫ�����������ýϴ����
    self.attraction = 0         -- ������,�����˿����ɻ����ٶ�
    self.moveType = 0
    self.cfgMoveType = 0

    self:initByCfg( cfg )
end

function cItem:initByCfg( cfg )
	if not cfg then
		return false
	end

	self.cfgId = cfg.id
	self.group = cfg.group
    self.hp = 1

    self.classify = cfg.classify
    self.count = cfg.count
    self.acceleration = cfg.G
    self.dampingX = cfg.dampingX
    self.initSpeed = cfg.initSpeed
    self.followDistance = cfg.followDistance
    self.attraction = cfg.attraction
    self.moveType = cfg.moveType
    self.cfgMoveType = cfg.moveType

	-- �����ش���
	self.viewIds = cfg.viewIds 	-- �ж���̬,��Ӧ�˸�����
	self.currentViewId = self.viewIds[self.unitLevel]
	self.deadViewId = cfg.deadViewId

	if not self.currentViewId then
		self.currentViewId = self.viewIds[1]
	end

	self:setView(self.currentViewId) -- ����Ĭ�����

	return true
end

-- ÿ֡update
function cItem:update( dt )

	if not self:isValid() then
		return
	end

    if self.moveType == 0 then
	    self:move(dt)
    elseif self.moveType == 1 then
        self:move2(dt)
    end

    local x, y = self:getPosition()
	if y < -32 then
		self:remove()
	end

end

-- ���һԪ���η��̵�������
function cItem.QuadraticEquations(a,b,c)
    local delta = b * b - 4 * a * c
    if delta < 0 then
        return nil, nil
    end

    local sqrt_delta = math.sqrt(delta)
    local a2 = 2 * a
    return (-b + sqrt_delta) / a2, (-b - sqrt_delta) / a2
end

-- �����ƶ�����
function cItem:move( dt )
	if not self.view then
		return
	end

    --��õ��ߵ�λ��
	local x,y = self:getPosition()

    local plane = self.world.plane

    local speedX
    if plane and (plane.hp > 0) then

        --��÷ɻ���λ��
        local tx,ty = plane:getPosition()
        --���������ɻ�֮��ľ����
        local dx,dy = tx - x, ty - y

        --����������;�в��������ģʽ���������ı��ֶ�����ߵı�ըЧ��
        --(ҲΪ�˺���һԪ���η��̵ĵڶ�������������Ҫ�Ľ�)
        if not self.following and self.speedY < 0 then
            local distance = math.sqrt(dx * dx + dy * dy)
            --�����ɻ��ľ���,С�ڸ��������������ģʽ
            if distance <= self.followDistance + plane:adsorptionDistance() then
                self.following = true
            end
        end
    
        if self.following and y > ty then   --����ģʽ��,�����ڷɻ����Ϸ�
            --���ݵ�����ɻ��Ĵ�ֱ����,�������ٶ�,��ǰ�ٶȼ��� ���ߵ���ɻ��߶���Ҫ��ʱ��t
            local _, t = cItem.QuadraticEquations(self.acceleration * 0.5, self.speedY, -dy)
            --��tʱ����,������ɻ��ĺ������Ϊ0,��Ŀ���ٶ�speedXӦ����:
            speedX = dx * 2 / t - self.speedX
        else
            --��Ϊ��ʼ��ʱ��,�����������ܱ�ը������,Ϊ�˱�����߷�ɢ̫��,�ں������������,�Ӷ����ϼ�С������ٶ�
            speedX = self.speedX - self.speedX * self.dampingX * dt
        end

    else
        --��Ϊ��ʼ��ʱ��,�����������ܱ�ը������,Ϊ�˱�����߷�ɢ̫��,�ں������������,�Ӷ����ϼ�С������ٶ�
        speedX = self.speedX - self.speedX * self.dampingX * dt
    end

    --���������ٶ����������ٶ�Ӱ��
    local speedY = self.speedY + self.acceleration * dt

	x = x + (self.speedX + speedX) * dt * 0.5
	y = y + (self.speedY + speedY) * dt * 0.5
    self.speedX = speedX
    self.speedY = speedY

	self:pos(x, y)

	return x, y
end

-- ����Ļ�ڵ����İ汾
function cItem:move2( dt )
	if not self.view then
		return
	end

    -- ���ɻ���Ч��ʱ��, ��ת������ģʽ
    --[[
    local plane = self.world.plane
    if plane and (plane.hp > 0) then
        --��÷ɻ���λ��
        local tx,ty = plane:getPosition()
        if self.y - 100 > ty or self.y > display.height - 50 then
            self.moveType = 0
            self.following = true

            return self:move(dt)
        end
    end
    --]]
    
	local world = self.world

    --�����Ļ������
    local x, y = world:convertToScreen(self.x, self.y, self.zvalue)

    --������Ļ����ϵ���µ�λ��
	x = x + self.speedX * dt
	y = y + self.speedY * dt

    --�޶�����Ļ��Χ��
    if x < 0 then
        x = -x
        self.speedX = math.abs(self.speedX)
    end
    if x > display.width then 
        x = display.width * 2 - x
        self.speedX = -math.abs(self.speedX) 
    end
    if y < 0 then 
        y = -y
        self.speedY = math.abs(self.speedY) 
    end
    if y > display.height then 
        y = display.height * 2 - y
        self.speedY = -math.abs(self.speedY) 
    end

    --ת��Ϊս���е�����
    x, y = world:convertToWorld(x, y, self.zvalue)

    --����λ��
    self:pos(x, y)

	return x, y
end

-- ���ݽǶ����ó�ʼ��X,Y������ٶ�
function cItem:startAngle(angle)
    self.speedX = math.sin(angle) * self.initSpeed
    self.speedY = math.cos(angle) * self.initSpeed
end

function cItem:onEntrance()
    self.hp = 1
    self.moveType = self.cfgMoveType
end
